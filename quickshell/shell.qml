import Quickshell
import QtQuick
import "components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitWidth: 2000
            implicitHeight: 44
            exclusiveZone: 0
            color: "transparent"

            Command {
                id: cursor
                command: ["sh", "-c", "hyprctl cursorpos"]
                parser: data => {
                    const [x, y] = data.trim().split(",").map(v => parseInt(v, 10))
                    return { x: x, y: y }
                }
                interval: 50
            }

            Rectangle {
                id: leftBox
                y: 0
                width: 220
                height: parent.height
                color: "transparent"
                anchors.left: parent.left
            }

            Rectangle {
                id: rightBox
                y: 0
                width: 120
                height: parent.height
                color: "transparent"
                anchors.right: parent.right
            }

            WorkspacesPill {
                id: pill
                x: dodge.pill ? leftBox.width + 12 : 10
                y: 2

                Behavior on x {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ClockPill {
                id: clock
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.rightMargin: dodge.clock ? rightBox.width + 12 : 10

                Behavior on anchors.rightMargin {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            QtObject {
                id: dodge
                property bool pill: {
                    const lx = (cursor.value?.x ?? 0) - modelData.x
                    const ly = (cursor.value?.y ?? 0) - modelData.y
                    return lx >= leftBox.x && lx <= leftBox.x + leftBox.width &&
                           ly >= leftBox.y && ly <= leftBox.y + leftBox.height
                }
                property bool clock: {
                    const lx = (cursor.value?.x ?? 0) - modelData.x
                    const ly = (cursor.value?.y ?? 0) - modelData.y
                    return lx >= rightBox.x && lx <= rightBox.x + rightBox.width &&
                           ly >= rightBox.y && ly <= rightBox.y + rightBox.height
                }
            }

            mask: Region {
                Region { item: pill }
                Region { item: clock }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            id: statsWindow
            screen: modelData

            anchors { top: true; left: true; right: true }
            height: statsPanel.height
            exclusiveZone: 0
            color: "transparent"

            mask: Region {
                Region { item: statsPanel.sensor }
                Region { item: statsPanel.body }
            }

            StatsPanel {
                id: statsPanel
                anchors.horizontalCenter: parent.horizontalCenter
                window: statsWindow
            }
        }
    }
}