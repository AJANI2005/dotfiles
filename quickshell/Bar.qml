// Bottom bar. Modules are data: edit `layout` and `registry` to add/remove them.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
  id: bar

  visible: BarState.visible
  color: "transparent"
  anchors { left: true; right: true; bottom: true }
  implicitHeight: Theme.barHeight
  exclusionMode: ExclusionMode.Auto
  WlrLayershell.namespace: "qs-bar"

  property var registry: ({
    workspaces: workspaceComponent,
    clock: clockComponent,
    updates: updateComponent,
    tray: trayComponent,
    battery: batteryComponent
  })

  property var layout: ({
    left: ["workspaces"],
    center: ["clock"],
    right: ["updates", "tray", "battery"]
  })

  Component { id: workspaceComponent; WorkspaceWidget {} }
  Component { id: clockComponent; ClockWidget {} }
  Component { id: updateComponent; UpdateWidget {} }
  Component { id: trayComponent; TrayWidget {} }
  Component { id: batteryComponent; BatteryWidget {} }

  Rectangle {
    anchors.fill: parent
    color: Theme.panel
    Rectangle {
      anchors { left: parent.left; right: parent.right; top: parent.top }
      height: 1
      color: Theme.border
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Theme.pad
    anchors.rightMargin: Theme.pad
    spacing: Theme.gap

    RowLayout {
      spacing: Theme.gap
      Repeater {
        model: bar.layout.left
        delegate: Loader { sourceComponent: bar.registry[modelData] }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      RowLayout {
        anchors.centerIn: parent
        spacing: Theme.gap
        Repeater {
          model: bar.layout.center
          delegate: Loader { sourceComponent: bar.registry[modelData] }
        }
      }
    }

    RowLayout {
      spacing: Theme.gap
      Repeater {
        model: bar.layout.right
        delegate: Loader { sourceComponent: bar.registry[modelData] }
      }
    }
  }
}
