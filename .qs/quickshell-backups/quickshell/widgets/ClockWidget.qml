// Bar component: date + time.
import QtQuick
import qs

Item {
  id: root
  implicitWidth: label.implicitWidth + 12
  implicitHeight: Theme.barHeight

  property var now: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: Qt.formatDateTime(root.now, "ddd dd MMM") + "   " + Qt.formatDateTime(root.now, "HH:mm")
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 12
  }
}
