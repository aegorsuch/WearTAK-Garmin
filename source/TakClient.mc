import Toybox.Communications;
import Toybox.Lang;
import Toybox.Position;
import Toybox.StringUtil;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Handles the connection to a TAK server and periodic location reporting.
//
// NOTE: The Connect IQ Communications API has no support for installing a
// client TLS certificate (mutual-TLS), so the standard TAK "certificate
// enrollment" flow used by ATAK/WinTAK cannot be performed on-device. Instead
// this connects over HTTPS using the entered username/password (HTTP Basic
// auth), which most TAK servers also accept for REST access.
class TakClient {
    var status as Symbol = :idle;
    var lastResponseCode as Number?  = null;
    var lastPosition as Position.Info?  = null;
    var reportTimer as Timer.Timer?  = null;
    var statusCallback as Method?  = null;

    function initialize() {
    }

    function updatePosition(info as Position.Info) as Void {
        lastPosition = info;
    }

    function isConnected() as Boolean {
        return status == :connected;
    }

    function connect() as Void {
        if (!TakSettings.isConfigured()) {
            status = :failed;
            lastResponseCode = null;
            return;
        }

        status = :connecting;

        var url = baseUrl() + "/Marti/api/version/config";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => authHeader(),
                "Accept" => "application/json"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, null, options, method(:onConnectResponse));
    }

    function onConnectResponse(responseCode as Number, data as String?) as Void {
        lastResponseCode = responseCode;
        if (responseCode == 200) {
            status = :connected;
            startReporting();
        } else {
            status = :failed;
            stopReporting();
        }
        notifyStatusChanged();
    }

    function disconnect() as Void {
        stopReporting();
        status = :idle;
        lastResponseCode = null;
    }

    function startReporting() as Void {
        if (reportTimer == null) {
            reportTimer = new Timer.Timer();
        }
        reportTimer.start(method(:sendLocation), 15000, true);
        sendLocation();
    }

    function stopReporting() as Void {
        if (reportTimer != null) {
            reportTimer.stop();
        }
    }

    function sendLocation() as Void {
        if (!isConnected() || lastPosition == null || lastPosition.position == null) {
            return;
        }

        var degrees = lastPosition.position.toDegrees();
        var payload = {
            "callsign" => callsign(),
            "lat" => degrees[0],
            "lon" => degrees[1],
            "altitude" => lastPosition.altitude,
            "time" => System.getTimer()
        };

        var url = baseUrl() + "/Marti/api/location";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Authorization" => authHeader(),
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, payload, options, method(:onLocationResponse));
    }

    function onLocationResponse(responseCode as Number, data as String?) as Void {
        lastResponseCode = responseCode;
        if (responseCode != 200) {
            status = :failed;
            stopReporting();
        }
        notifyStatusChanged();
    }

    function notifyStatusChanged() as Void {
        if (statusCallback != null) {
            statusCallback.invoke();
        }
    }

    function baseUrl() as String {
        return "https://" + TakSettings.getServerUrl() + ":" + TakSettings.getPort();
    }

    function callsign() as String {
        var name = TakSettings.getServerName();
        return name.equals("") ? TakSettings.getUsername() : name;
    }

    function authHeader() as String {
        var credentials = TakSettings.getUsername() + ":" + TakSettings.getPassword();
        return "Basic " + StringUtil.encodeBase64(credentials);
    }

    function statusText() as String {
        if (status == :connecting) {
            return WatchUi.loadResource(Rez.Strings.StatusConnecting);
        } else if (status == :connected) {
            return WatchUi.loadResource(Rez.Strings.StatusConnected);
        } else if (status == :failed) {
            var text = WatchUi.loadResource(Rez.Strings.StatusFailed);
            if (lastResponseCode != null) {
                text = text + " (" + lastResponseCode.toString() + ")";
            }
            return text;
        }
        return WatchUi.loadResource(Rez.Strings.StatusIdle);
    }
}
