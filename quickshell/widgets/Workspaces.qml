// Bar component: workspace badges (1-9).
import QtQuick
import Quickshell.Hyprland

Row {
  id: root
  spacing: 4

  Repeater {
    model: 9

    delegate: Rectangle {
      required property int index
      readonly property int wsId: index + 1
      readonly property bool focused: {
        const f = Hyprland.focusedWorkspace
        return f !== null && f !== undefined && f.id === wsId
      }
      readonly property bool occupied: {
        for (const w of Hyprland.workspaces.values) {
          if (w.id === wsId) return w.toplevels.values.length > 0
        }
        return false
      }

      width: 20
      height: 20
      radius: 6
      anchors.verticalCenter: parent.verticalCenter
      color: "transparent"

      Text {
        anchors.centerIn: parent
        text: parent.wsId
        color: parent.focused ? "#7aa2f7" : (parent.occupied ? "#e6e7f0" : "#6b7280")
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.bold: parent.focused
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + parent.wsId)
      }
    }
  }
}