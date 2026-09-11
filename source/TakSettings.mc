import Toybox.Application;
import Toybox.Lang;

// Persists the user-entered TAK server connection details between app launches.
module TakSettings {
    const KEY_SERVER_URL = "tak.serverUrl";
    const KEY_SERVER_NAME = "tak.serverName";
    const KEY_USERNAME = "tak.username";
    const KEY_PASSWORD = "tak.password";
    const KEY_PORT = "tak.port";
    const KEY_TRACKING_MODE = "tak.trackingMode";
    const KEY_ALERT_INTERVAL = "tak.alertInterval";
    const KEY_MOVING_INTERVAL = "tak.movingInterval";
    const KEY_STATIONARY_INTERVAL = "tak.stationaryInterval";
    const KEY_STATIC_INTERVAL = "tak.staticInterval";
    const KEY_INCOMING_COT_PATH = "tak.incomingCotPath";
    const KEY_INCOMING_COT_INTERVAL = "tak.incomingCotInterval";
    const KEY_HEALTH_TELEMETRY_ENABLED = "tak.healthTelemetryEnabled";

    function getServerUrl() as String {
        var value = Application.Storage.getValue(KEY_SERVER_URL);
        return value == null ? "" : value;
    }

    function setServerUrl(value as String) as Void {
        Application.Storage.setValue(KEY_SERVER_URL, value);
    }

    function getServerName() as String {
        var value = Application.Storage.getValue(KEY_SERVER_NAME);
        return value == null ? "" : value;
    }

    function setServerName(value as String) as Void {
        Application.Storage.setValue(KEY_SERVER_NAME, value);
    }

    function getCallsign() as String {
        var value = Application.Storage.getValue(KEY_SERVER_NAME);
        return value == null || value.equals("") ? "Garmin" : value;
    }

    function setCallsign(value as String) as Void {
        Application.Storage.setValue(KEY_SERVER_NAME, value);
    }

    function getUsername() as String {
        var value = Application.Storage.getValue(KEY_USERNAME);
        return value == null ? "" : value;
    }

    function setUsername(value as String) as Void {
        Application.Storage.setValue(KEY_USERNAME, value);
    }

    function getPassword() as String {
        var value = Application.Storage.getValue(KEY_PASSWORD);
        return value == null ? "" : value;
    }

    function setPassword(value as String) as Void {
        Application.Storage.setValue(KEY_PASSWORD, value);
    }

    function getPort() as String {
        var value = Application.Storage.getValue(KEY_PORT);
        return value == null ? "8089" : value;
    }

    function setPort(value as String) as Void {
        Application.Storage.setValue(KEY_PORT, value);
    }

    function getTrackingMode() as Symbol {
        return Application.Storage.getValue(KEY_TRACKING_MODE) == "static" ? :static : :dynamic;
    }

    function setTrackingMode(mode as Symbol) as Void {
        Application.Storage.setValue(KEY_TRACKING_MODE, mode == :static ? "static" : "dynamic");
    }

    function getAlertInterval() as String {
        return getInterval(KEY_ALERT_INTERVAL, "10");
    }

    function setAlertInterval(value as String) as Void {
        Application.Storage.setValue(KEY_ALERT_INTERVAL, value);
    }

    function getMovingInterval() as String {
        return getInterval(KEY_MOVING_INTERVAL, "60");
    }

    function setMovingInterval(value as String) as Void {
        Application.Storage.setValue(KEY_MOVING_INTERVAL, value);
    }

    function getStationaryInterval() as String {
        return getInterval(KEY_STATIONARY_INTERVAL, "3600");
    }

    function setStationaryInterval(value as String) as Void {
        Application.Storage.setValue(KEY_STATIONARY_INTERVAL, value);
    }

    function getStaticInterval() as String {
        return getInterval(KEY_STATIC_INTERVAL, "60");
    }

    function setStaticInterval(value as String) as Void {
        Application.Storage.setValue(KEY_STATIC_INTERVAL, value);
    }

    function getIncomingCotPath() as String {
        return getInterval(KEY_INCOMING_COT_PATH, "");
    }

    function setIncomingCotPath(value as String) as Void {
        Application.Storage.setValue(KEY_INCOMING_COT_PATH, value);
    }

    function getIncomingCotInterval() as String {
        return getInterval(KEY_INCOMING_COT_INTERVAL, "60");
    }

    function setIncomingCotInterval(value as String) as Void {
        Application.Storage.setValue(KEY_INCOMING_COT_INTERVAL, value);
    }

    function isHealthTelemetryEnabled() as Boolean {
        return Application.Storage.getValue(KEY_HEALTH_TELEMETRY_ENABLED) == "true";
    }

    function setHealthTelemetryEnabled(enabled as Boolean) as Void {
        Application.Storage.setValue(KEY_HEALTH_TELEMETRY_ENABLED, enabled ? "true" : "false");
    }

    function getInterval(key as String, defaultValue as String) as String {
        var value = Application.Storage.getValue(key);
        return value == null ? defaultValue : value;
    }

    function isConfigured() as Boolean {
        return !getServerUrl().equals("") && !getUsername().equals("") && !getPassword().equals("");
    }
}
