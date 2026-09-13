//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

ShellRoot {
    id: root

    // ---- dark grayscale palette ----
    readonly property color bg: '#0d0d0d'
    readonly property color fg: '#e6e6e6'
    readonly property color occupied: '#c0c0c0'
    readonly property color dim: '#5c5c5c'

    function workspace(id) {
        const list = Hyprland.workspaces.values
        for (const w of list) {
            if (w.id === id) return w
        }
        return null
    }

    // Wallpaper Switcher
    WallpaperSwitcher{}

    // Bar
    PanelWindow {
        id: bar
        anchors {
            bottom: true
            left: true
            right: true
        }
        height: 14
        color: "#cc0d0d0d"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Row {
                spacing: 0

                Repeater {
                    model: 9

                    Rectangle {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var wsObj: root.workspace(wsId)
                        readonly property bool isFocused: Hyprland.focusedWorkspace !== null
                                                          && Hyprland.focusedWorkspace.id === wsId
                        readonly property bool isOccupied: wsObj !== null
                                                          && wsObj.toplevels.values.length > 0

                        width: 18
                        height: 14
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.wsId
                            color: parent.isFocused
                                     ? root.fg
                                     : (parent.isOccupied ? root.occupied : root.dim)
                            font.pixelSize: 10
                            font.bold: parent.isFocused
                            font.family: "monospace"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + parent.wsId)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                height: 14
            }

            Rectangle {
                height: 14
                implicitWidth: dateText.implicitWidth + timeText.implicitWidth + 8
                color: "transparent"

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: dateText
                        color: root.dim
                        font.pixelSize: 11
                        font.family: "monospace"
                    }

                    Text {
                        id: timeText
                        color: root.fg
                        font.pixelSize: 11
                        font.family: "monospace"
                    }
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        let d = new Date()
                        dateText.text = Qt.formatDateTime(d, "yyyy-MM-dd")
                        timeText.text = Qt.formatDateTime(d, "h:mm:ss AP")
                    }
                }
            }
        }

        Row {
            spacing: 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: SystemTray.items

                Rectangle {
                    id: trayDelegate
                    required property var modelData
                    readonly property var trayItem: modelData

                    width: 18
                    height: 14
                    color: "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: parent.trayItem.icon
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    QsMenuAnchor {
                        id: trayMenu
                        menu: trayDelegate.trayItem.menu
                        anchor.window: bar
                        anchor.edges: Quickshell.Edges.Top | Quickshell.Edges.Left
                        anchor.gravity: Quickshell.Edges.Top
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            const it = parent.trayItem
                            const openMenu = () => {
                                const pos = parent.mapToItem(bar.contentItem, 0, 0)
                                trayMenu.anchor.rect.x = pos.x
                                trayMenu.anchor.rect.y = pos.y
                                trayMenu.anchor.rect.width = parent.width
                                trayMenu.anchor.rect.height = parent.height
                                trayMenu.open()
                            }
                            if (mouse.button === Qt.RightButton) {
                                if (it.menu) openMenu()
                                else it.secondaryActivate()
                            } else if (it.onlyMenu && it.menu) {
                                openMenu()
                            } else {
                                it.activate()
                            }
                        }
                    }
                }
            }
        }
    }
}
