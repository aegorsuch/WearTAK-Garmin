import Toybox.Lang;
import Toybox.WatchUi;

function buildSosMenu(app as StandaloneApp) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitleSos)});
    if (app.getTakClient().isAlerting()) {
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelClearSos), null, :clear, null));
    } else {
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelSendSos), null, :send, null));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.LabelCancel), null, :cancel, null));
    }
    return menu;
}

class SosMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app as StandaloneApp;

    function initialize(application as StandaloneApp) {
        Menu2InputDelegate.initialize();
        app = application;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :send) {
            app.getTakClient().sendSosEvent();
        } else if (item.getId() == :clear) {
            app.getTakClient().setAlerting(false);
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}