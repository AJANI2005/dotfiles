import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

// Minimal top bar modelled on omarchy's: sharp-edged, near-black, Nerd Font.
// Left: workspaces (active turns into a glyph, click=switch).
// Center: (none — clock moved right).
// Right: system tray.
//
// Component of shell.qml — instantiated by the main shell entry point.
Item {
    id: root

    readonly property color foreground: "#e9e6e1"

    readonly property string fontFamily: "0xProto Nerd Font Mono"
    readonly property int barHeight: 12

    function alpha(color, a) {
        return Qt.rgba(color.r, color.g, color.b, a);
    }
    function workspaceFor(id) {
        const list = Hyprland.workspaces.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i];
        return null;
    }

    // ---- one bar per monitor ----
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: root.barHeight
            exclusiveZone: root.barHeight
            color: "transparent"
            WlrLayershell.namespace: "qs-bar"
            WlrLayershell.layer: WlrLayer.Top

            // left: workspaces
            Row {
                id: leftRow
                height: parent.height
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    margins: 8
                }
                spacing: 1

                Repeater {
                    model: [1, 2, 3, 4, 5, 6, 7, 8, 9]
                    delegate: Item {
                        required property int modelData
                        width: 20
                        height: leftRow.height
                        readonly property var ws: root.workspaceFor(modelData)
                        readonly property bool active: ws !== null && ws.focused
                        readonly property bool occupied: ws !== null

                        Text {
                            anchors.centerIn: parent
                            text: active ? "󱓻" : String(modelData % 10)
                            color: root.alpha(root.foreground, active ? 1 : (occupied ? 0.9 : 0.4))
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: active ? Font.Bold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + modelData)
                        }
                    }
                }
            }

// right: clock + system tray
            Row {
                id: rightRow
                height: parent.height
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 8
                }
                spacing: 4

                // clock
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
                    }
                }

                Repeater {
                    model: SystemTray.items
                    delegate: Item {
                        id: trayItem
                        required property var modelData
                        width: 22
                        height: rightRow.height

                        IconImage {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            source: modelData.icon
                            visible: modelData.icon !== ""
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                                    const r = QsWindow.itemRect(trayItem);
                                    modelData.display(panel, r.x, r.y + trayItem.height);
                                } else if (mouse.button === Qt.LeftButton) {
                                    modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}