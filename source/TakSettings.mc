import Toybox.Application;
import Toybox.Lang;

// Persists local Garmin relay and identity settings between app launches.
module TakSettings {
    const KEY_CALLSIGN = "tak.callsign";
    const KEY_TEAM = "tak.team";
    const KEY_ROLE = "tak.role";
    const KEY_TRACKING_MODE = "tak.trackingMode";
    const KEY_ALERT_INTERVAL = "tak.alertInterval";
    const KEY_MOVING_INTERVAL = "tak.movingInterval";
    const KEY_STATIONARY_INTERVAL = "tak.stationaryInterval";
    const KEY_STATIC_INTERVAL = "tak.staticInterval";
    const KEY_HEALTH_TELEMETRY_ENABLED = "tak.healthTelemetryEnabled";

    function getCallsign() as String {
        var value = Application.Storage.getValue(KEY_CALLSIGN);
        return value == null || value.equals("") ? "Garmin" : value;
    }

    function setCallsign(value as String) as Void {
        Application.Storage.setValue(KEY_CALLSIGN, value);
    }

    function getTeam() as Symbol {
        return Application.Storage.getValue(KEY_TEAM) == "red" ? :red : :blue;
    }

    function setTeam(team as Symbol) as Void {
        Application.Storage.setValue(KEY_TEAM, team == :red ? "red" : "blue");
    }

    function getRole() as Symbol {
        var value = Application.Storage.getValue(KEY_ROLE);
        return value == "lead" ? :lead : value == "medic" ? :medic : :member;
    }

    function setRole(role as Symbol) as Void {
        var value = role == :lead ? "lead" : role == :medic ? "medic" : "member";
        Application.Storage.setValue(KEY_ROLE, value);
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

}
