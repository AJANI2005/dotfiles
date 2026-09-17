// Bar component: workspace badges (1-9).
import QtQuick
import qs

Row {
  id: root
  spacing: 4

  Repeater {
    model: 9

    delegate: Rectangle {
      required property int index
      readonly property int wsId: index + 1
      readonly property bool focused: Workspaces.isFocused(wsId)
      readonly property bool occupied: Workspaces.isOccupied(wsId)

      width: 20
      height: 20
      radius: 6
      anchors.verticalCenter: parent.verticalCenter
      color: focused ? Theme.accent : (occupied ? Theme.raised : "transparent")

      Text {
        anchors.centerIn: parent
        text: parent.wsId
        color: parent.focused ? Theme.bg : (parent.occupied ? Theme.text : Theme.faint)
        font.family: Theme.font
        font.pixelSize: 11
        font.bold: parent.focused
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Workspaces.focus(parent.wsId)
      }
    }
  }
}
