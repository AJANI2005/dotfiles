// Bottom bar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "widgets" 

PanelWindow {
  id: bar

  anchors { left: true; right: true; bottom: true }
  implicitHeight: 20
  color: "transparent"
  exclusionMode: ExclusionMode.Auto
  WlrLayershell.namespace: "qs-bar"

  Rectangle {
    anchors.fill: parent
    color: "#141419"
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 6

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Workspaces {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Item {
      Layout.fillHeight: true

      Clock {
        id: clock
        anchors.centerIn: parent
      }

      Updates {
        anchors.right: clock.left
        anchors.rightMargin: 16
        anchors.verticalCenter: clock.verticalCenter
      }

      Battery {
        anchors.left: clock.right
        anchors.leftMargin: 16
        anchors.verticalCenter: clock.verticalCenter
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Tray {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
