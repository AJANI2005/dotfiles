// Bar component: pending update count; click to upgrade.
import QtQuick
import qs

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Updates.runUpgrade()
  }

  Row {
    id: row
    spacing: 6
    anchors.verticalCenter: parent.verticalCenter

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰚰"
      color: Updates.count > 0 ? Theme.accent : Theme.faint
      font.family: Theme.font
      font.pixelSize: 13
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Updates.count
      color: Updates.count > 0 ? Theme.accent : Theme.dim
      font.family: Theme.font
      font.pixelSize: 12
    }
  }
}
