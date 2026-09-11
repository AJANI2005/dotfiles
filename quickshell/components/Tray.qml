import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    property var window: null

    signal entered()
    signal exited()

    width: trayRow.width
    height: 24

    Component.onCompleted: {
        console.log("[tray] startup items:", trayRepeater.count)
    }

    Connections {
        target: SystemTray.items
        function onCountChanged() {
            console.log("[tray] items changed:", trayRepeater.count)
        }
    }

    Row {
        id: trayRow

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: delegateItem
                required property var modelData

                width: 22
                height: root.height

                Rectangle {
                    id: hoverBg
                    anchors.fill: parent
                    radius: 4
                    color: "transparent"
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: delegateItem.modelData.icon
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: delegateItem.modelData.menu
                    anchor.window: root.window
                    anchor.rect: {
                        const pos = delegateItem.mapToItem(null, 0, 0)
                        return Qt.rect(pos.x, pos.y, delegateItem.width, delegateItem.height)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    ToolTip.delay: 500
                    ToolTip.visible: containsMouse
                    ToolTip.text: delegateItem.modelData.tooltipTitle

                    onEntered: root.entered()
                    onExited: root.exited()

                    onContainsMouseChanged: {
                        hoverBg.color = containsMouse ? "#282520" : "transparent"
                    }

                    onClicked: event => {
                        if (event.button === Qt.RightButton) {
                            menuAnchor.open()
                        } else if (delegateItem.modelData.onlyMenu && delegateItem.modelData.hasMenu) {
                            menuAnchor.open()
                        } else {
                            delegateItem.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}