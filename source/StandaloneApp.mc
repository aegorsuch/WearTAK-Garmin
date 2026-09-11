import Toybox.Application;
import Toybox.Position;
import Toybox.WatchUi;

class StandaloneApp extends Application.AppBase {
    private var view;
    private var takClient;

    function initialize() {
        Application.AppBase.initialize();
        takClient = new TakClient();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onStart(params) {
    }

    function onPosition(info as Toybox.Position.Info) as Void {
        takClient.updatePosition(info);
        if (view != null) {
            view.updatePosition(info);
        }
    }

    function getMapView() as StandaloneMapView {
        if (view == null) {
            view = new StandaloneMapView();
        }
        return view;
    }

    function getTakClient() as TakClient {
        return takClient;
    }

    function getInitialView() {
        var menu = buildMainMenu();
        return [menu, new MainMenuDelegate(self)];
    }
}
