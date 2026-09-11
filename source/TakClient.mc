import Toybox.Communications;
import Toybox.Lang;
import Toybox.Position;
import Toybox.StringUtil;
import Toybox.System;
import Toybox.Time;
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
    var scheduledInterval as Number? = null;
    var moving as Boolean = false;
    var alerting as Boolean = false;
    var statusCallback as Method?  = null;

    function initialize() {
    }

    function updatePosition(info as Position.Info) as Void {
        lastPosition = info;
        var wasMoving = moving;
        moving = info.speed != null && info.speed >= 0.5;
        if (wasMoving != moving && isConnected() && TakSettings.getTrackingMode() == :dynamic) {
            scheduleReporting(false);
        }
    }

    function setAlerting(value as Boolean) as Void {
        if (alerting == value) {
            return;
        }
        alerting = value;
        if (isConnected() && TakSettings.getTrackingMode() == :dynamic) {
            scheduleReporting(false);
        }
    }

    function refreshReportingSchedule() as Void {
        if (isConnected()) {
            scheduleReporting(false);
        }
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
        scheduleReporting(true);
        sendLocation();
    }

    function stopReporting() as Void {
        if (reportTimer != null) {
            reportTimer.stop();
        }
        scheduledInterval = null;
    }

    function scheduleReporting(force as Boolean) as Void {
        var interval = reportingIntervalSeconds() * 1000;
        if (!force && scheduledInterval == interval) {
            return;
        }
        if (reportTimer == null) {
            reportTimer = new Timer.Timer();
        }
        reportTimer.stop();
        reportTimer.start(method(:sendLocation), interval, true);
        scheduledInterval = interval;
    }

    function reportingIntervalSeconds() as Number {
        if (TakSettings.getTrackingMode() == :static) {
            return configuredInterval(TakSettings.getStaticInterval(), 60);
        }
        if (alerting) {
            return configuredInterval(TakSettings.getAlertInterval(), 10);
        }
        if (moving) {
            return configuredInterval(TakSettings.getMovingInterval(), 60);
        }
        return configuredInterval(TakSettings.getStationaryInterval(), 3600);
    }

    function configuredInterval(value as String, defaultSeconds as Number) as Number {
        var seconds = value.toNumber();
        return seconds == null || seconds <= 0 ? defaultSeconds : seconds;
    }

    function sendLocation() as Void {
        if (!isConnected() || lastPosition == null || lastPosition.position == null) {
            return;
        }

        var degrees = lastPosition.position.toDegrees();
        var payload = buildPliEvent(degrees[0], degrees[1], lastPosition.altitude);

        var url = baseUrl() + "/Marti/api/cot";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Authorization" => authHeader(),
                "Content-Type" => "application/xml"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, payload, options, method(:onLocationResponse));
    }

    function buildPliEvent(latitude, longitude, altitude) as String {
        var now = cotTimestamp(Time.now());
        var stale = cotTimestamp(Time.now().add(new Time.Duration(60)));
        var safeCallsign = xmlEscape(callsign());
        var uid = xmlEscape("garmin-" + callsign());
        var hae = altitude == null ? "9999999.0" : altitude.toString();

        return "<event version=\"2.0\" uid=\"" + uid + "\" type=\"a-f-G-U-C\" time=\"" + now + "\" start=\"" + now + "\" stale=\"" + stale + "\" how=\"m-g\">"
            + "<point lat=\"" + latitude.toString() + "\" lon=\"" + longitude.toString() + "\" hae=\"" + hae + "\" ce=\"9999999.0\" le=\"9999999.0\"/>"
            + "<detail><contact callsign=\"" + safeCallsign + "\"/><uid Droid=\"" + safeCallsign + "\"/></detail></event>";
    }

    function cotTimestamp(moment as Time.Moment) as String {
        var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.year.format("%04d") + "-" + info.month.format("%02d") + "-" + info.day.format("%02d")
            + "T" + info.hour.format("%02d") + ":" + info.min.format("%02d") + ":" + info.sec.format("%02d") + "Z";
    }

    function xmlEscape(value as String) as String {
        var escaped = "";
        for (var index = 0; index < value.length(); index++) {
            var character = value.substring(index, index + 1);
            if (character.equals("&")) {
                escaped += "&amp;";
            } else if (character.equals("<")) {
                escaped += "&lt;";
            } else if (character.equals(">")) {
                escaped += "&gt;";
            } else if (character.equals("\"")) {
                escaped += "&quot;";
            } else if (character.equals("'")) {
                escaped += "&apos;";
            } else {
                escaped += character;
            }
        }
        return escaped;
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
