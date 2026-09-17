// Bar component: battery percentage via UPower.
import QtQuick
import Quickshell.Services.UPower
import qs

Row {
  id: root
  spacing: 6
  visible: !!UPower.displayDevice

  readonly property var dev: UPower.displayDevice
  readonly property bool charging: !!dev
    && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged)
  readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.charging ? "󰂄"
      : root.pct >= 80 ? "󰂁"
      : root.pct >= 50 ? "󰂀"
      : root.pct >= 20 ? "󰁾"
      : "󰁺"
    color: root.pct <= 15 && !root.charging ? Theme.bad : Theme.text
    font.family: Theme.font
    font.pixelSize: 14
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.pct + "%"
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 12
  }
}
