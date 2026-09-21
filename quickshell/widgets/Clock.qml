// Bar component: day + 24h time, e.g. "Thursday 16:00".
import QtQuick

Item {
  id: root
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  property string text

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.text = new Date().toLocaleString(Qt.locale(), "dddd HH:mm")
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    font.bold: true
    color: "#e6e7f0"
  }
}
