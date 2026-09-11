import Toybox.Application;
import Toybox.Lang;

// Persists the user-entered TAK server connection details between app launches.
module TakSettings {
    const KEY_SERVER_URL = "tak.serverUrl";
    const KEY_SERVER_NAME = "tak.serverName";
    const KEY_USERNAME = "tak.username";
    const KEY_PASSWORD = "tak.password";
    const KEY_PORT = "tak.port";

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

    function isConfigured() as Boolean {
        return !getServerUrl().equals("") && !getUsername().equals("") && !getPassword().equals("");
    }
}
