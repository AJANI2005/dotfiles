// Bar component: pending update count; click to upgrade.
import QtQuick
import qs

Row {
  id: root
  spacing: 6

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

  TapHandler {
    cursorShape: Qt.PointingHandCursor
    onTapped: Updates.runUpgrade()
  }
}
