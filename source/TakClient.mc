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
    var incomingTimer as Timer.Timer? = null;
    var reconnectTimer as Timer.Timer? = null;
    var scheduledInterval as Number? = null;
    var reconnectAttempts as Number = 0;
    var moving as Boolean = false;
    var alerting as Boolean = false;
    var statusCallback as Method?  = null;
    var incomingCotCallback as Method? = null;

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

    function isAlerting() as Boolean {
        return alerting;
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
            reconnectAttempts = 0;
            startReporting();
            startIncomingPolling();
        } else {
            handleRequestFailure();
        }
        notifyStatusChanged();
    }

    function disconnect() as Void {
        stopReporting();
        stopIncomingPolling();
        stopReconnectTimer();
        alerting = false;
        reconnectAttempts = 0;
        status = :idle;
        lastResponseCode = null;
        notifyStatusChanged();
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

    function startIncomingPolling() as Void {
        if (TakSettings.getIncomingCotPath().equals("")) {
            return;
        }
        if (incomingTimer == null) {
            incomingTimer = new Timer.Timer();
        }
        incomingTimer.stop();
        incomingTimer.start(method(:fetchIncomingCot), configuredInterval(TakSettings.getIncomingCotInterval(), 60) * 1000, true);
        fetchIncomingCot();
    }

    function stopIncomingPolling() as Void {
        if (incomingTimer != null) {
            incomingTimer.stop();
        }
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

    function sendMarker(id as String, location as Position.Location, type as Symbol, label as String) as Void {
        if (!isConnected()) {
            return;
        }
        var degrees = location.toDegrees();
        var payload = buildMarkerEvent(id, degrees[0], degrees[1], type, label);
        sendCotEvent(payload, method(:onMarkerResponse));
    }

    function sendSosEvent() as Void {
        if (!isConnected() || lastPosition == null || lastPosition.position == null) {
            return;
        }
        setAlerting(true);
        var degrees = lastPosition.position.toDegrees();
        sendCotEvent(buildSosEvent(degrees[0], degrees[1], lastPosition.altitude), method(:onSosResponse));
    }

    function fetchIncomingCot() as Void {
        if (!isConnected() || TakSettings.getIncomingCotPath().equals("")) {
            return;
        }
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Authorization" => authHeader(), "Accept" => "application/xml"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };
        Communications.makeWebRequest(baseUrl() + TakSettings.getIncomingCotPath(), null, options, method(:onIncomingCotResponse));
    }

    function sendCotEvent(payload as String, callback as Method) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {"Authorization" => authHeader(), "Content-Type" => "application/xml"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };
        Communications.makeWebRequest(baseUrl() + "/Marti/api/cot", payload, options, callback);
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

    function buildMarkerEvent(id as String, latitude, longitude, type as Symbol, label as String) as String {
        var now = cotTimestamp(Time.now());
        var stale = cotTimestamp(Time.now().add(new Time.Duration(3600)));
        var markerType = type == :hostile ? "a-h-G-E-S" : type == :friendly ? "a-f-G-E-S" : type == :obstacle ? "a-o-G-E-S" : "a-u-G-E-S";
        var name = xmlEscape(label);
        return "<event version=\"2.0\" uid=\"" + xmlEscape("garmin-" + callsign() + "-marker-" + id) + "\" type=\"" + markerType + "\" time=\"" + now + "\" start=\"" + now + "\" stale=\"" + stale + "\" how=\"m-g\">"
            + "<point lat=\"" + latitude.toString() + "\" lon=\"" + longitude.toString() + "\" hae=\"9999999.0\" ce=\"9999999.0\" le=\"9999999.0\"/>"
            + "<detail><contact callsign=\"" + name + "\"/></detail></event>";
    }

    function buildSosEvent(latitude, longitude, altitude) as String {
        var now = cotTimestamp(Time.now());
        var stale = cotTimestamp(Time.now().add(new Time.Duration(3600)));
        var hae = altitude == null ? "9999999.0" : altitude.toString();
        var safeCallsign = xmlEscape(callsign());
        return "<event version=\"2.0\" uid=\"" + xmlEscape("garmin-" + callsign() + "-sos") + "\" type=\"b-a-o-tbl\" time=\"" + now + "\" start=\"" + now + "\" stale=\"" + stale + "\" how=\"m-g\">"
            + "<point lat=\"" + latitude.toString() + "\" lon=\"" + longitude.toString() + "\" hae=\"" + hae + "\" ce=\"9999999.0\" le=\"9999999.0\"/>"
            + "<detail><contact callsign=\"" + safeCallsign + "\"/><emergency type=\"911\" callsign=\"" + safeCallsign + "\"/></detail></event>";
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
            handleRequestFailure();
        }
        notifyStatusChanged();
    }

    function onMarkerResponse(responseCode as Number, data as String?) as Void {
        lastResponseCode = responseCode;
        if (responseCode != 200) {
            handleRequestFailure();
        }
        notifyStatusChanged();
    }

    function onSosResponse(responseCode as Number, data as String?) as Void {
        lastResponseCode = responseCode;
        if (responseCode != 200) {
            handleRequestFailure();
        }
        notifyStatusChanged();
    }

    function onIncomingCotResponse(responseCode as Number, data as String?) as Void {
        lastResponseCode = responseCode;
        if (responseCode == 200 && data != null) {
            parseIncomingCot(data);
        } else if (responseCode != 200) {
            handleRequestFailure();
        }
        notifyStatusChanged();
    }

    function parseIncomingCot(data as String) as Void {
        var remaining = data;
        var count = 0;
        while (count < 50) {
            var start = remaining.find("<event");
            if (start == null) {
                return;
            }
            remaining = remaining.substring(start, remaining.length());
            var end = remaining.find("</event>");
            if (end == null) {
                return;
            }
            var event = remaining.substring(0, end + 8);
            remaining = remaining.substring(end + 8, remaining.length());
            var pointStart = event.find("<point");
            if (pointStart != null) {
                var point = event.substring(pointStart, event.length());
                var latitude = cotAttribute(point, "lat");
                var longitude = cotAttribute(point, "lon");
                var uid = cotAttribute(event, "uid");
                var type = cotAttribute(event, "type");
                if (latitude != null && longitude != null && uid != null && type != null && incomingCotCallback != null) {
                    incomingCotCallback.invoke(uid, latitude.toNumber(), longitude.toNumber(), type);
                }
            }
            count += 1;
        }
    }

    function cotAttribute(xml as String, name as String) as String? {
        var prefix = name + "=\"";
        var start = xml.find(prefix);
        if (start == null) {
            return null;
        }
        var value = xml.substring(start + prefix.length(), xml.length());
        var end = value.find("\"");
        return end == null ? null : value.substring(0, end);
    }

    function handleRequestFailure() as Void {
        stopReporting();
        stopIncomingPolling();
        scheduleReconnect();
    }

    function scheduleReconnect() as Void {
        if (reconnectAttempts >= 3) {
            status = :failed;
            return;
        }
        if (reconnectTimer == null) {
            reconnectTimer = new Timer.Timer();
        }
        var delay = reconnectAttempts == 0 ? 5000 : reconnectAttempts == 1 ? 15000 : 60000;
        reconnectAttempts += 1;
        status = :retrying;
        reconnectTimer.stop();
        reconnectTimer.start(method(:retryConnection), delay, false);
    }

    function retryConnection() as Void {
        connect();
    }

    function stopReconnectTimer() as Void {
        if (reconnectTimer != null) {
            reconnectTimer.stop();
        }
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
        } else if (status == :retrying) {
            return WatchUi.loadResource(Rez.Strings.StatusRetrying) + " (" + reconnectAttempts.toString() + "/3)";
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
