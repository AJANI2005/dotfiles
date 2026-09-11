import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root

    readonly property var focusedWs: Hyprland.focusedWorkspace

    implicitWidth: row.width + 14
    implicitHeight: 22
    radius: 11
    color: "#16130f"
    border { width: 1; color: "#38332d" }

    QtObject {
        id: wsLookup
        property var byId: ({})

        function rebuild() {
            const map = {}
            const list = Hyprland.workspaces.values
            for (let i = 0; i < list.length; ++i) {
                const ws = list[i]
                if (ws && ws.id >= 1 && ws.id <= 9 && map[ws.id] === undefined) {
                    map[ws.id] = ws
                }
            }
            wsLookup.byId = map
        }

        Connections {
            target: Hyprland.workspaces
            function onObjectInsertedPost() { wsLookup.rebuild() }
            function onObjectRemovedPost() { wsLookup.rebuild() }
        }

        Component.onCompleted: wsLookup.rebuild()
    }

    Row {
        id: row
        anchors {
            left: parent.left
            leftMargin: 7
            verticalCenter: parent.verticalCenter
        }
        spacing: 5

        Repeater {
            model: 9

            delegate: Item {
                required property int index
                readonly property int wsId: index + 1
                readonly property var ws: wsLookup.byId[wsId]
                readonly property bool isActive: focusedWs ? focusedWs.id === wsId : false
                readonly property int clientCount: ws && ws.toplevels ? ws.toplevels.values.length : 0
                readonly property bool isOccupied: clientCount > 0

                width: 8
                height: 8

                Rectangle {
                    anchors.centerIn: parent
                    radius: width / 2
                    width: 6
                    height: 6
                    color: isActive
                        ? "#e87962"
                        : (isOccupied ? "#8a8378" : "#4a443c")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + wsId)
                }
            }
        }
    }
}