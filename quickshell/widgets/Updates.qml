// Bar component: pending update count from pacman.
import QtQuick
import Quickshell.Io

Item {
  id: root
  implicitWidth: iconRow.implicitWidth
  implicitHeight: iconRow.implicitHeight

  property int count: 0

  Process {
    id: poll
    command: ["bash", "-c", "paru -Qu 2>/dev/null | wc -l"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const n = parseInt(String(text).trim())
        root.count = isNaN(n) ? 0 : n
      }
    }
  }

  Timer {
    interval: 1800000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: poll.running = true
  }

  Process {
    id: upgrade
    command: ["alacritty","--hold", "-e", "paru", "-Syu"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: upgrade.startDetached()
  }

  Text {
    id: label
    anchors.fill: parent
    verticalAlignment: Text.AlignVCenter

    Row {
      id: iconRow
      anchors.centerIn: parent
      spacing: 5

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰚰"
        color: root.count > 0 ? "#7aa2f7" : "#6b7280"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.count
        color: root.count > 0 ? "#7aa2f7" : "#6b7280"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
      }
    }
  }
}
