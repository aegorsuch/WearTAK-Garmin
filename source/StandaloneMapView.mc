import Toybox.Graphics;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class StandaloneMapMarker extends WatchUi.MapMarker {
    function initialize(location) {
        MapMarker.initialize(location);
    }
}

class StandaloneMapView extends WatchUi.MapTrackView {
    var screenWidth;
    var screenHeight;
    var mapTopLeft;
    var mapBottomRight;
    var markers = {};
    var pointLocations = {};
    var controlSize = 40;
    var controlGap = 6;
    var controlMargin = 8;

    function initialize() {
        WatchUi.MapTrackView.initialize();
        screenWidth = System.getDeviceSettings().screenWidth;
        screenHeight = System.getDeviceSettings().screenHeight;
        setScreenVisibleArea(0, 0, screenWidth, screenHeight);
        setMapMode(WatchUi.MAP_MODE_BROWSE);
        centerOn(null);
    }

    function updatePosition(info) {
        if (info == null || info.position == null) {
            return;
        }

        if (mapTopLeft == null) {
            centerOn(info.position);
        }

        var selfMarker = new StandaloneMapMarker(info.position);
        var selfIcon = WatchUi.loadResource(Rez.Drawables.TargetIcon);
        selfMarker.setIcon(selfIcon, selfIcon.getWidth() / 2, selfIcon.getHeight() / 2);
        selfMarker.setLabel("SELF");
        markers.put("self", selfMarker);
        setMapMarker(markers.values());
        WatchUi.requestUpdate();
    }

    function centerOn(position) {
        var center = [0.0, 0.0];
        if (position != null) {
            center = position.toDegrees();
        }
        var span = 0.005;
        mapTopLeft = new Position.Location({:latitude => center[0] + span, :longitude => center[1] - span, :format => :degrees});
        mapBottomRight = new Position.Location({:latitude => center[0] - span, :longitude => center[1] + span, :format => :degrees});
        setMapVisibleArea(mapTopLeft, mapBottomRight);
    }

    function onUpdate(dc) {
        var left = controlMargin;
        var top = (screenHeight - (controlSize * 3 + controlGap * 2)) / 2;
        drawControl(dc, left, top, "+");
        drawTargetControl(dc, left, top + controlSize + controlGap);
        drawControl(dc, left, top + (controlSize + controlGap) * 2, "-");
        drawBackControl(dc, screenWidth - controlSize - controlMargin, (screenHeight - controlSize) / 2);
    }

    function drawControl(dc, x, y, label) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, controlSize, controlSize);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, controlSize, controlSize);
        dc.drawText(x + controlSize / 2, y + 4, Graphics.FONT_LARGE, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawTargetControl(dc, x, y) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, controlSize, controlSize);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, controlSize, controlSize);
        var centerX = x + controlSize / 2;
        var centerY = y + controlSize / 2;
        dc.drawCircle(centerX, centerY, 11);
        dc.drawLine(centerX - 16, centerY, centerX - 5, centerY);
        dc.drawLine(centerX + 5, centerY, centerX + 16, centerY);
        dc.drawLine(centerX, centerY - 16, centerX, centerY - 5);
        dc.drawLine(centerX, centerY + 5, centerX, centerY + 16);
    }

    function drawBackControl(dc, x, y) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, controlSize, controlSize);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, controlSize, controlSize);
        var centerX = x + controlSize / 2;
        var centerY = y + controlSize / 2;
        dc.drawLine(centerX + 10, centerY - 12, centerX - 8, centerY);
        dc.drawLine(centerX - 8, centerY, centerX + 10, centerY + 12);
    }

    function dropAtCurrentLocation() {
        var info = Position.getInfo();
        if (info != null && info.position != null) {
            addPoint(info.position, :unknown, "Unknown 2525D point");
        }
    }

    function snapToSelf() {
        var info = Position.getInfo();
        if (info != null && info.position != null) {
            setMapMode(WatchUi.MAP_MODE_BROWSE);
            centerOn(info.position);
            WatchUi.requestUpdate();
        }
    }

    function dropAtScreen(x, y) {
        if (mapTopLeft == null || mapBottomRight == null) {
            return;
        }
        var topLeft = mapTopLeft.toDegrees();
        var bottomRight = mapBottomRight.toDegrees();
        var xRatio = x.toFloat() / screenWidth.toFloat();
        var yRatio = y.toFloat() / screenHeight.toFloat();
        var latitude = topLeft[0] + (bottomRight[0] - topLeft[0]) * yRatio;
        var longitude = topLeft[1] + (bottomRight[1] - topLeft[1]) * xRatio;
        addPoint(new Position.Location({:latitude => latitude, :longitude => longitude, :format => :degrees}), :unknown, "Unknown 2525D point");
    }

    function addPoint(location, type, label) {
        var id = Time.now().value().toString();
        var marker = new StandaloneMapMarker(location);
        var icon = iconForType(type);
        marker.setIcon(icon, icon.getWidth() / 2, icon.getHeight() / 2);
        marker.setLabel(label);
        markers.put(id, marker);
        pointLocations.put(id, location);
        setMapMarker(markers.values());
        PersistedContent.saveWaypoint(location, {:name => label});
        WatchUi.requestUpdate();
    }

    function iconForType(type) {
        if (type == :friendly) {
            return WatchUi.loadResource(Rez.Drawables.FriendlyIcon);
        } else if (type == :hostile) {
            return WatchUi.loadResource(Rez.Drawables.HostileIcon);
        } else if (type == :obstacle) {
            return WatchUi.loadResource(Rez.Drawables.ObstacleIcon);
        }
        return WatchUi.loadResource(Rez.Drawables.UnknownIcon);
    }

    function pointAtScreen(x, y) {
        var topLeft = mapTopLeft.toDegrees();
        var bottomRight = mapBottomRight.toDegrees();
        var keys = pointLocations.keys();
        for (var i = 0; i < keys.size(); i++) {
            var location = pointLocations.get(keys[i]).toDegrees();
            var markerX = (location[1] - topLeft[1]) / (bottomRight[1] - topLeft[1]) * screenWidth;
            var markerY = (topLeft[0] - location[0]) / (topLeft[0] - bottomRight[0]) * screenHeight;
            var dx = markerX - x;
            var dy = markerY - y;
            if (dx * dx + dy * dy <= 22 * 22) {
                return keys[i];
            }
        }
        return null;
    }

    function changePointType(id, type, label) {
        if (pointLocations.hasKey(id) == false) {
            return;
        }
        var location = pointLocations.get(id);
        var marker = new StandaloneMapMarker(location);
        var icon = iconForType(type);
        marker.setIcon(icon, icon.getWidth() / 2, icon.getHeight() / 2);
        marker.setLabel(label);
        markers.put(id, marker);
        setMapMarker(markers.values());
        PersistedContent.saveWaypoint(location, {:name => label});
        WatchUi.requestUpdate();
    }

    function zoom(scale) {
        var topLeft = mapTopLeft.toDegrees();
        var bottomRight = mapBottomRight.toDegrees();
        var centerLat = (topLeft[0] + bottomRight[0]) / 2;
        var centerLon = (topLeft[1] + bottomRight[1]) / 2;
        var halfLat = (topLeft[0] - bottomRight[0]) * scale / 2;
        var halfLon = (bottomRight[1] - topLeft[1]) * scale / 2;
        mapTopLeft = new Position.Location({:latitude => centerLat + halfLat, :longitude => centerLon - halfLon, :format => :degrees});
        mapBottomRight = new Position.Location({:latitude => centerLat - halfLat, :longitude => centerLon + halfLon, :format => :degrees});
        setMapVisibleArea(mapTopLeft, mapBottomRight);
        WatchUi.requestUpdate();
    }

    function pan(direction) {
        var topLeft = mapTopLeft.toDegrees();
        var bottomRight = mapBottomRight.toDegrees();
        var latShift = (topLeft[0] - bottomRight[0]) * 0.25;
        var lonShift = (bottomRight[1] - topLeft[1]) * 0.25;
        var latOffset = 0.0;
        var lonOffset = 0.0;
        if (direction == WatchUi.SWIPE_UP) {
            latOffset = latShift;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            latOffset = -latShift;
        } else if (direction == WatchUi.SWIPE_LEFT) {
            lonOffset = -lonShift;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            lonOffset = lonShift;
        }
        mapTopLeft = new Position.Location({:latitude => topLeft[0] + latOffset, :longitude => topLeft[1] + lonOffset, :format => :degrees});
        mapBottomRight = new Position.Location({:latitude => bottomRight[0] + latOffset, :longitude => bottomRight[1] + lonOffset, :format => :degrees});
        setMapVisibleArea(mapTopLeft, mapBottomRight);
        WatchUi.requestUpdate();
    }
}

class StandaloneMapDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(mapView) {
        WatchUi.BehaviorDelegate.initialize();
        view = mapView;
    }

    function onTap(evt) {
        var coordinates = evt.getCoordinates();
        var left = view.controlMargin;
        var right = view.screenWidth - view.controlSize - view.controlMargin;
        var top = (view.screenHeight - (view.controlSize * 3 + view.controlGap * 2)) / 2;
        var backTop = (view.screenHeight - view.controlSize) / 2;
        if (coordinates[0] >= right && coordinates[0] <= right + view.controlSize && coordinates[1] >= backTop && coordinates[1] <= backTop + view.controlSize) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        if (coordinates[0] < left || coordinates[0] > left + view.controlSize) {
            var pointId = view.pointAtScreen(coordinates[0], coordinates[1]);
            if (pointId != null) {
                showPointTypeMenu(pointId);
                return true;
            }
            return false;
        }
        if (coordinates[1] >= top && coordinates[1] < top + view.controlSize) {
            view.zoom(0.5);
        } else if (coordinates[1] >= top + view.controlSize + view.controlGap && coordinates[1] < top + (view.controlSize * 2) + view.controlGap) {
            view.snapToSelf();
        } else if (coordinates[1] >= top + (view.controlSize + view.controlGap) * 2) {
            view.zoom(2.0);
        } else {
            return false;
        }
        return true;
    }

    function showPointTypeMenu(pointId) {
        var menu = new WatchUi.Menu2({:title => "2525D Point"});
        menu.addItem(new WatchUi.MenuItem("Friendly", null, :friendly, null));
        menu.addItem(new WatchUi.MenuItem("Unknown", null, :unknown, null));
        menu.addItem(new WatchUi.MenuItem("Hostile", null, :hostile, null));
        menu.addItem(new WatchUi.MenuItem("Obstacle", null, :obstacle, null));
        WatchUi.pushView(menu, new PointTypeMenuDelegate(view, pointId), WatchUi.SLIDE_UP);
    }

    function onHold(evt) {
        var coordinates = evt.getCoordinates();
        view.dropAtScreen(coordinates[0], coordinates[1]);
        return true;
    }

    function onSwipe(evt) {
        view.pan(evt.getDirection());
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class PointTypeMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;
    var pointId;

    function initialize(mapView, id) {
        Menu2InputDelegate.initialize();
        view = mapView;
        pointId = id;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :friendly) {
            view.changePointType(pointId, :friendly, "Friendly 2525D point");
        } else if (id == :hostile) {
            view.changePointType(pointId, :hostile, "Hostile 2525D point");
        } else if (id == :obstacle) {
            view.changePointType(pointId, :obstacle, "Obstacle 2525D point");
        } else {
            view.changePointType(pointId, :unknown, "Unknown 2525D point");
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
