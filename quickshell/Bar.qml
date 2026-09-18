// Bottom bar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
  id: bar

  visible: BarState.visible
  color: Theme.panel
  anchors { left: true; right: true; bottom: true }
  implicitHeight: Theme.barHeight
  exclusionMode: ExclusionMode.Auto
  WlrLayershell.namespace: "qs-bar"

  Rectangle {
    anchors { left: parent.left; right: parent.right; top: parent.top }
    height: 1
    color: Theme.border
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Theme.pad
    anchors.rightMargin: Theme.pad
    spacing: Theme.gap

    RowLayout {
      spacing: Theme.gap
      WorkspaceWidget {}
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      RowLayout {
        anchors.centerIn: parent
        spacing: Theme.gap
        ClockWidget {}
      }
    }

    RowLayout {
      spacing: Theme.gap
      UpdateWidget {}
      TrayWidget {}
      BatteryWidget {}
    }
  }
}
