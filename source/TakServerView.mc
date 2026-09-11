import Toybox.Lang;
import Toybox.WatchUi;

// Builds the TAK server connection settings menu.
function buildTakServerMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitleTakServer)});
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelServerUrl), displayValue(TakSettings.getServerUrl()), :serverUrl, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelServerName), displayValue(TakSettings.getServerName()), :serverName, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelUsername), displayValue(TakSettings.getUsername()), :username, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelPassword), maskedPassword(), :password, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelPort), displayValue(TakSettings.getPort()), :port, null));
    menu.addItem(new WatchUi.MenuItem(connectActionLabel(), null, :toggleConnect, null));
    return menu;
}

function displayValue(value as String) as String {
    return value.equals("") ? WatchUi.loadResource(Rez.Strings.LabelNotSet) : value;
}

function maskedPassword() as String {
    var password = TakSettings.getPassword();
    if (password.equals("")) {
        return WatchUi.loadResource(Rez.Strings.LabelNotSet);
    }
    var masked = "";
    for (var i = 0; i < password.length(); i++) {
        masked = masked + "*";
    }
    return masked;
}

function connectActionLabel() as String {
    return WatchUi.loadResource(Rez.Strings.LabelConnect);
}

class TakServerMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app as StandaloneApp;
    var menu as WatchUi.Menu2;

    function initialize(application as StandaloneApp, takMenu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        app = application;
        menu = takMenu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :serverUrl) {
            editField(:serverUrl, TakSettings.getServerUrl());
        } else if (id == :serverName) {
            editField(:serverName, TakSettings.getServerName());
        } else if (id == :username) {
            editField(:username, TakSettings.getUsername());
        } else if (id == :password) {
            editField(:password, TakSettings.getPassword());
        } else if (id == :port) {
            editField(:port, TakSettings.getPort());
        } else if (id == :toggleConnect) {
            toggleConnect();
        }
    }

    function editField(fieldId as Symbol, currentValue as String) as Void {
        WatchUi.pushView(
            new WatchUi.TextPicker(currentValue),
            new TakFieldTextPickerDelegate(self, fieldId),
            WatchUi.SLIDE_UP
        );
    }

    function onFieldEntered(fieldId as Symbol, text as String) as Void {
        if (fieldId == :serverUrl) {
            TakSettings.setServerUrl(text);
        } else if (fieldId == :serverName) {
            TakSettings.setServerName(text);
        } else if (fieldId == :username) {
            TakSettings.setUsername(text);
        } else if (fieldId == :password) {
            TakSettings.setPassword(text);
        } else if (fieldId == :port) {
            TakSettings.setPort(text);
        }
        refreshItem(fieldId);
    }

    function refreshItem(fieldId as Symbol) as Void {
        var item = menu.getItem(menu.findItemById(fieldId));
        if (item == null) {
            return;
        }
        if (fieldId == :password) {
            item.setSubLabel(maskedPassword());
        } else if (fieldId == :serverUrl) {
            item.setSubLabel(displayValue(TakSettings.getServerUrl()));
        } else if (fieldId == :serverName) {
            item.setSubLabel(displayValue(TakSettings.getServerName()));
        } else if (fieldId == :username) {
            item.setSubLabel(displayValue(TakSettings.getUsername()));
        } else if (fieldId == :port) {
            item.setSubLabel(displayValue(TakSettings.getPort()));
        }
        WatchUi.requestUpdate();
    }

    function toggleConnect() as Void {
        var client = app.getTakClient();
        if (client.isConnected()) {
            client.disconnect();
        } else {
            client.connect();
        }
        client.statusCallback = method(:onClientStatusChanged);
        updateStatusItem();
    }

    function onClientStatusChanged() as Void {
        updateStatusItem();
    }

    function updateStatusItem() as Void {
        var client = app.getTakClient();
        var item = menu.getItem(menu.findItemById(:toggleConnect));
        if (item == null) {
            return;
        }
        var label = client.isConnected() ? WatchUi.loadResource(Rez.Strings.LabelDisconnect) : WatchUi.loadResource(Rez.Strings.LabelConnect);
        item.setLabel(label);
        item.setSubLabel(client.statusText());
        WatchUi.requestUpdate();
    }

    function getMenu() as WatchUi.Menu2 {
        return menu;
    }
}

class TakFieldTextPickerDelegate extends WatchUi.TextPickerDelegate {
    var parent as TakServerMenuDelegate;
    var fieldId as Symbol;

    function initialize(parentDelegate as TakServerMenuDelegate, field as Symbol) {
        TextPickerDelegate.initialize();
        parent = parentDelegate;
        fieldId = field;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (changed) {
            parent.onFieldEntered(fieldId, text);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}
