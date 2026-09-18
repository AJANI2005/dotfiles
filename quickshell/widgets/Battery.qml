// Bar component: battery shown as a glowing ring.
import QtQuick
import Quickshell.Io

Item {
  id: root
  implicitWidth: 14 + (root.hovered ? label.implicitWidth + 4 : 0)
  implicitHeight: 14

  property real charge: 0
  property real animCharge: 0
  property bool hovered: false

  readonly property color ringColor:
    root.charge >= 0.5 ? "#9ece6a"
    : root.charge >= 0.2 ? "#e0af68"
    : "#f7768e"

  Process {
    id: readBattery
    command: ["bash", "-c",
      "c=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); "
      + "[ -n \"$c\" ] || c=$(upower -d 2>/dev/null | awk '/percentage:/{gsub(/%/,\"\"); print $2; exit}'); "
      + "echo ${c:-0}"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const n = parseInt(String(text).trim())
        root.charge = Math.max(0, Math.min(1, (isNaN(n) ? 0 : n) / 100))
      }
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: readBattery.running = true
  }

  onChargeChanged: root.animCharge = root.charge

  Behavior on animCharge {
    NumberAnimation { duration: 600; easing.type: Easing.OutQuart }
  }

  Canvas {
    id: ring
    width: 14
    height: 14

    property real charge: root.animCharge

    onChargeChanged: requestPaint()

    onPaint: () => {
      const ctx = ring.getContext("2d")
      ctx.reset()
      const c = ring.width / 2
      const r = (ring.width - 6) / 2
      const a0 = -Math.PI / 2
      const a1 = a0 + 2 * Math.PI * ring.charge

      ctx.lineCap = "round"

      ctx.strokeStyle = root.ringColor
      for (let i = 3; i >= 1; i--) {
        ctx.globalAlpha = 0.08
        ctx.lineWidth = 2 + i * 1.5
        ctx.beginPath()
        ctx.arc(c, c, r, a0, a1)
        ctx.stroke()
      }

      ctx.globalAlpha = 1
      ctx.strokeStyle = "#2a2a33"
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.arc(c, c, r, 0, 2 * Math.PI)
      ctx.stroke()

      ctx.strokeStyle = root.ringColor
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.arc(c, c, r, a0, a1)
      ctx.stroke()
      ctx.globalAlpha = 1
    }
  }

  Text {
    id: label
    opacity: root.hovered ? 1 : 0
    anchors.left: ring.right
    anchors.leftMargin: 4
    anchors.verticalCenter: ring.verticalCenter
    text: Math.round(root.charge * 100) + "%"
    color: root.ringColor
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 11
    font.bold: true

    Behavior on opacity {
      NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: root.hovered = true
    onExited: root.hovered = false
  }
}