import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: root

    // ---- dark grayscale palette ----
    readonly property color bg: '#0d0d0d'
    readonly property color fg: '#e6e6e6'
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
                        readonly property bool isFocused: wsObj !== null && wsObj.focused
                        readonly property bool isOccupied: wsObj !== null && wsObj.toplevels.count > 0

                        width: 18
                        height: 14
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.wsId
                            color: parent.isFocused ? root.fg : root.dim
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
    }
}
