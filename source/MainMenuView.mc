import Toybox.Lang;
import Toybox.WatchUi;

// Builds the app's main menu: choose the map view or configure phone relay settings.
function buildMainMenu() as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitleMain)});
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuItemMap), null, :map, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuItemChat), null, :chat, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuItemSos), null, :sos, null));
    menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.MenuItemTakServer), null, :takServer, null));
    return menu;
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var app as StandaloneApp;

    function initialize(application as StandaloneApp) {
        Menu2InputDelegate.initialize();
        app = application;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :map) {
            var mapView = app.getMapView();
            mapView.setTakClient(app.getTakClient());
            WatchUi.pushView(mapView, new StandaloneMapDelegate(mapView), WatchUi.SLIDE_LEFT);
        } else if (id == :chat) {
            var chatMenu = buildChatMenu(app);
            WatchUi.pushView(chatMenu, new ChatMenuDelegate(app), WatchUi.SLIDE_LEFT);
        } else if (id == :sos) {
            var sosMenu = buildSosMenu(app);
            WatchUi.pushView(sosMenu, new SosMenuDelegate(app), WatchUi.SLIDE_LEFT);
        } else if (id == :takServer) {
            var takMenu = buildTakServerMenu();
            WatchUi.pushView(takMenu, new TakServerMenuDelegate(app, takMenu), WatchUi.SLIDE_LEFT);
        }
    }
}
