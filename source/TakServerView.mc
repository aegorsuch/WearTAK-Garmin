import Toybox.Lang;
import Toybox.WatchUi;

// Builds the phone relay controls. ATAK owns identity and reporting.
function buildTakServerMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitleTakServer)});
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelSosControl), null, :sos, null));
    menu.addItem(new WatchUi.MenuItem(connectActionLabel(), null, :toggleConnect, null));
    return menu;
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
        if (id == :sos) {
            showSosConfirmation();
        } else if (id == :toggleConnect) {
            toggleConnect();
        }
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
