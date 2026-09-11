import Toybox.Lang;
import Toybox.WatchUi;

// Builds phone relay and local reporting settings. ATAK owns server access.
function buildTakServerMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitleTakServer)});
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelServerName), displayValue(TakSettings.getCallsign()), :serverName, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelTeam), TakSettings.getTeam().toString(), :team, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelRole), TakSettings.getRole().toString(), :role, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelTrackingMode), trackingModeLabel(), :trackingMode, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelAlertInterval), TakSettings.getAlertInterval(), :alertInterval, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelMovingInterval), TakSettings.getMovingInterval(), :movingInterval, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelStationaryInterval), TakSettings.getStationaryInterval(), :stationaryInterval, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelStaticInterval), TakSettings.getStaticInterval(), :staticInterval, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelHealthTelemetry), healthTelemetryLabel(), :healthTelemetry, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelSosControl), null, :sos, null));
    menu.addItem(new WatchUi.MenuItem(connectActionLabel(), null, :toggleConnect, null));
    return menu;
}

function displayValue(value as String) as String {
    return value.equals("") ? WatchUi.loadResource(Rez.Strings.LabelNotSet) : value;
}

function connectActionLabel() as String {
    return WatchUi.loadResource(Rez.Strings.LabelConnect);
}

function trackingModeLabel() as String {
    return TakSettings.getTrackingMode() == :static
        ? WatchUi.loadResource(Rez.Strings.TrackingModeStatic)
        : WatchUi.loadResource(Rez.Strings.TrackingModeDynamic);
}

function healthTelemetryLabel() as String {
    return TakSettings.isHealthTelemetryEnabled()
        ? WatchUi.loadResource(Rez.Strings.LabelEnabled)
        : WatchUi.loadResource(Rez.Strings.LabelDisabled);
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
        if (id == :serverName) {
            editField(:serverName, TakSettings.getCallsign());
        } else if (id == :team) {
            showTeamMenu();
        } else if (id == :role) {
            showRoleMenu();
        } else if (id == :trackingMode) {
            showTrackingModeMenu();
        } else if (id == :alertInterval) {
            editField(:alertInterval, TakSettings.getAlertInterval());
        } else if (id == :movingInterval) {
            editField(:movingInterval, TakSettings.getMovingInterval());
        } else if (id == :stationaryInterval) {
            editField(:stationaryInterval, TakSettings.getStationaryInterval());
        } else if (id == :staticInterval) {
            editField(:staticInterval, TakSettings.getStaticInterval());
        } else if (id == :healthTelemetry) {
            TakSettings.setHealthTelemetryEnabled(!TakSettings.isHealthTelemetryEnabled());
            refreshItem(:healthTelemetry);
        } else if (id == :sos) {
            showSosConfirmation();
        } else if (id == :toggleConnect) {
            toggleConnect();
        }
    }

    function showTrackingModeMenu() as Void {
        var trackingMenu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.LabelTrackingMode)});
        trackingMenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.TrackingModeDynamic), null, :dynamic, null));
        trackingMenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.TrackingModeStatic), null, :static, null));
        WatchUi.pushView(trackingMenu, new TrackingModeMenuDelegate(self), WatchUi.SLIDE_UP);
    }

    function showTeamMenu() as Void {
        var teamMenu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.LabelTeam)});
        teamMenu.addItem(new WatchUi.MenuItem("Blue", null, :blue, null));
        teamMenu.addItem(new WatchUi.MenuItem("Red", null, :red, null));
        WatchUi.pushView(teamMenu, new IdentityMenuDelegate(self, :team), WatchUi.SLIDE_UP);
    }

    function showRoleMenu() as Void {
        var roleMenu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.LabelRole)});
        roleMenu.addItem(new WatchUi.MenuItem("Member", null, :member, null));
        roleMenu.addItem(new WatchUi.MenuItem("Lead", null, :lead, null));
        roleMenu.addItem(new WatchUi.MenuItem("Medic", null, :medic, null));
        WatchUi.pushView(roleMenu, new IdentityMenuDelegate(self, :role), WatchUi.SLIDE_UP);
    }

    function onIdentitySelected(field as Symbol, value) as Void {
        if (field == :team) {
            TakSettings.setTeam(value);
        } else {
            TakSettings.setRole(value);
        }
        refreshItem(field);
    }

    function onTrackingModeSelected(mode) as Void {
        TakSettings.setTrackingMode(mode);
        refreshItem(:trackingMode);
        app.getTakClient().refreshReportingSchedule();
    }

    function showSosConfirmation() as Void {
        if (app.getTakClient().isAlerting()) {
            app.getTakClient().setAlerting(false);
            return;
        }
        var confirmation = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.ConfirmSosTitle)});
        confirmation.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelSendSos), null, :send, null));
        confirmation.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelCancel), null, :cancel, null));
        WatchUi.pushView(confirmation, new SosConfirmationDelegate(self), WatchUi.SLIDE_UP);
    }

    function sendSos() as Void {
        app.getTakClient().sendSosEvent();
    }

    function editField(fieldId as Symbol, currentValue as String) as Void {
        WatchUi.pushView(
            new WatchUi.TextPicker(currentValue),
            new TakFieldTextPickerDelegate(self, fieldId),
            WatchUi.SLIDE_UP
        );
    }

    function onFieldEntered(fieldId as Symbol, text as String) as Void {
        if (fieldId == :serverName) {
            TakSettings.setCallsign(text);
        } else if (fieldId == :alertInterval) {
            TakSettings.setAlertInterval(text);
        } else if (fieldId == :movingInterval) {
            TakSettings.setMovingInterval(text);
        } else if (fieldId == :stationaryInterval) {
            TakSettings.setStationaryInterval(text);
        } else if (fieldId == :staticInterval) {
            TakSettings.setStaticInterval(text);
        }
        refreshItem(fieldId);
        app.getTakClient().refreshReportingSchedule();
    }

    function refreshItem(fieldId as Symbol) as Void {
        var item = menu.getItem(menu.findItemById(fieldId));
        if (item == null) {
            return;
        }
        if (fieldId == :serverName) {
            item.setSubLabel(displayValue(TakSettings.getCallsign()));
        } else if (fieldId == :team) {
            item.setSubLabel(TakSettings.getTeam().toString());
        } else if (fieldId == :role) {
            item.setSubLabel(TakSettings.getRole().toString());
        } else if (fieldId == :trackingMode) {
            item.setSubLabel(trackingModeLabel());
        } else if (fieldId == :alertInterval) {
            item.setSubLabel(TakSettings.getAlertInterval());
        } else if (fieldId == :movingInterval) {
            item.setSubLabel(TakSettings.getMovingInterval());
        } else if (fieldId == :stationaryInterval) {
            item.setSubLabel(TakSettings.getStationaryInterval());
        } else if (fieldId == :staticInterval) {
            item.setSubLabel(TakSettings.getStaticInterval());
        } else if (fieldId == :healthTelemetry) {
            item.setSubLabel(healthTelemetryLabel());
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

class TrackingModeMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parent as TakServerMenuDelegate;

    function initialize(parentDelegate as TakServerMenuDelegate) {
        Menu2InputDelegate.initialize();
        parent = parentDelegate;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        parent.onTrackingModeSelected(item.getId());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class IdentityMenuDelegate extends WatchUi.Menu2InputDelegate {
    var parent as TakServerMenuDelegate;
    var field as Symbol;

    function initialize(parentDelegate as TakServerMenuDelegate, fieldId as Symbol) {
        Menu2InputDelegate.initialize();
        parent = parentDelegate;
        field = fieldId;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        parent.onIdentitySelected(field, item.getId());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class SosConfirmationDelegate extends WatchUi.Menu2InputDelegate {
    var parent as TakServerMenuDelegate;

    function initialize(parentDelegate as TakServerMenuDelegate) {
        Menu2InputDelegate.initialize();
        parent = parentDelegate;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :send) {
            parent.sendSos();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
