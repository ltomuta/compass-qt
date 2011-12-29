/*
 * Copyright (c) 2011 Nokia Corporation.
 */

import QtQuick 1.1
import com.nokia.meego 1.0
import "../common"



Page {
    id: mapView

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {

        ToolIcon {
            id: infoViewButton

            iconSource: "../images/icon_info_small.png"
            onClicked: {
                if (mapView.pageStack.currentPage === mapView) {
                    mapView.pageStack.push(Qt.resolvedUrl("InfoView.qml"));
                }
            }
        }

        ToolIcon {
            id: gpsIndicator

            iconSource: "../images/icon_gps_small.png"
            onClicked: map.panToCoordinate(map.hereCenter)
        }

        ToolIcon {
            id: compassMode

            property bool checked: false
            property string selectedString: checked ? "-selected" : ""

            iconSource: "../images/icon_compassmode_small" + selectedString + ".png"
            onClicked: { checked = !checked; }
        }

        ToolIcon {
            id: settingsToolButton

            property bool checked: false
            property string selectedString: checked ? "-selected" : ""

            //iconSource: "image://theme/icon-m-toolbar-settings-white" + selectedString
            platformIconId: "toolbar-settings-white" + selectedString
            onClicked: { checked = !checked; }
        }
    }

    Component.onCompleted: {
        mobility.active = true;

        var initialCoordinate = settingsPane.readSettings();

        map.mapCenter = initialCoordinate;
        map.hereCenter.longitude = initialCoordinate.longitude;
        map.hereCenter.latitude = initialCoordinate.latitude;

        settingsPane.readRoute(map.route);
    }

    Mobility {
        id: mobility

        screenSaverInhibited: settingsPane.screenSaverInhibited;

        onCompass: {
            // Find if there is already calibration view open in page stack
            var calibrationView = mapView.pageStack.find(function(page) {
                return page.objectName === "calibrationView";
            });

            // If it does not exist and it should be shown, create and push it
            // to the stack.
            if (calibrationLevel < 1.0 && calibrationView === null) {
                calibrationView = mapView.pageStack.push(
                            Qt.resolvedUrl("CalibrationView.qml"));
            }

            // If the calibration view exists, set the calibration level to it.
            if (calibrationView !== null) {
                calibrationView.setCalibrationLevel(calibrationLevel);
            }

            compass.azimuth = azimuth;
        }

        onPosition: {
            console.log("Position: " + coordinate.latitude +
                        ", " + coordinate.longitude +
                        " accuracy " + accuracyInMeters + " m");

            settingsPane.saveInitialCoordinate(coordinate);

            if (settingsPane.trackingOn === true && accuracyInMeters < 75) {
                // The recording is on and the GPS position is accurate
                // enough.
                settingsPane.saveRouteCoordinate(coordinate, time, accuracyInMeters);
                map.addRoute(coordinate);
            }

            map.moveHereToCoordinate(coordinate, accuracyInMeters);
        }
    }

    Image {
        id: background

        anchors.fill: parent

        source: "../images/compass_back.png"
        fillMode: Image.Tile
    }

    PannableMap {
        id: map

        anchors.fill: parent

        satelliteMap: settingsPane.satelliteMap
    }

    CompassPlate {
        id: compass

        x: 34

        // Turns automatically the bearing to the map north
        onUserRotatedCompass: compass.bearing = -compass.rotation
        bearingRotable: true
    }

    SettingsPane {
        id: settingsPane

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom; bottomMargin: parent.tools.height + 8
        }

        opacity: settingsToolButton.checked ? 1.0 : 0.0
        onClearRoute: map.clearRoute()
    }

    states: [
        State {
            when: !compassMode.checked
            name: "MapMode"
            PropertyChanges { target: map; opacity: 1.0 }
            PropertyChanges {
                target: compass
                opacity: 1.0
                width: 0.483607 * height; height: 0.40625 * mapView.height
                movable: true
                compassRotable: true
            }
        },
        State {
            when: compassMode.checked
            name: "TrackMode"
            PropertyChanges { target: map; opacity: 0 }
            PropertyChanges {
                target: compass
                opacity: 1.0; rotation: 0
                width: 0.483607 * height
                height: mapView.height
                x: (mapView.width - width) / 2; y: 0;
                movable: false
                compassRotable: false
            }
        }
    ]

    transitions: Transition {
        PropertyAnimation {
            properties: "x,y,width,height,opacity"
            duration: 500
            easing.type: Easing.InOutCirc
        }

        RotationAnimation {
            property: "rotation"
            duration: 500
            easing.type: Easing.InOutCirc
            direction:  RotationAnimation.Shortest
        }
    }
}
