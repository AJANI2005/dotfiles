import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "bar"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "JetBrainsMono Nerd Font"

  // ── Volume ────────────────────────────────────────────────────────
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  Connections {
    target: Pipewire.defaultAudioSink?.audio

    function onVolumeChanged() {
      root.shouldShowOsd = true;
      root.osdMode = "volume";
      hideTimer.restart();
    }
  }

  // ── Brightness ────────────────────────────────────────────────────
  property real brightnessValue: 0
  property real brightnessMax: 1

  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: {
      brightnessReadProc.running = true;
      root.shouldShowOsd = true;
      root.osdMode = "brightness";
      hideTimer.restart();
    }
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.brightnessMax > 0)
          root.brightnessValue = val / root.brightnessMax;
      }
    }
  }

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) root.brightnessMax = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  // ── Shared OSD state ──────────────────────────────────────────────
  property bool shouldShowOsd: false
  property string osdMode: "volume"

  Timer {
    id: hideTimer
    interval: 1000
    onTriggered: root.shouldShowOsd = false
  }

  readonly property real volumeValue: {
    const sink = Pipewire.defaultAudioSink;
    return sink && sink.audio ? sink.audio.volume : 0;
  }

  readonly property bool volumeMuted: {
    const sink = Pipewire.defaultAudioSink;
    return sink && sink.audio && sink.audio.muted;
  }

  readonly property string osdIcon: {
    if (root.osdMode === "brightness") return "󰃠";
    if (root.volumeMuted || root.volumeValue <= 0) return "󰖁";
    if (root.volumeValue < 0.33) return "󰕿";
    if (root.volumeValue < 0.66) return "󰖀";
    return "󰕾";
  }

  readonly property color osdColor: {
    if (root.osdMode === "brightness") return root.theme.accentOrange;
    if (root.volumeMuted) return root.theme.textMuted;
    return root.theme.accentPrimary;
  }

  readonly property real osdValue: {
    if (root.osdMode === "brightness") return root.brightnessValue;
    return root.volumeValue;
  }

  readonly property string osdValueText: {
    if (root.osdMode === "brightness") return Math.round(root.brightnessValue * 100) + "%";
    if (root.volumeMuted) return "Mute";
    return Math.round(root.volumeValue * 100) + "%";
  }

  // ── OSD window ────────────────────────────────────────────────────
  // The OSD window will be created and destroyed based on shouldShowOsd.
  // PanelWindow.visible could be set instead of using a loader, but using
  // a loader will reduce the memory overhead when the window isn't open.
  LazyLoader {
    active: root.shouldShowOsd

    PanelWindow {
      // Since the panel's screen is unset, it will be picked by the compositor
      // when the window is created. Most compositors pick the current active monitor.
      anchors.bottom: true
      margins.bottom: screen.height / 5
      exclusiveZone: 0

      implicitWidth: 320
      implicitHeight: 52
      color: "transparent"

      // An empty click mask prevents the window from blocking mouse events.
      mask: Region {}

      Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: "#e6000000"
        border.color: root.theme.bgBorder
        border.width: 1

        opacity: 0
        scale: 0.95

        ParallelAnimation {
          id: showAnim
          NumberAnimation {
            target: pill
            property: "opacity"
            from: 0
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: pill
            property: "scale"
            from: 0.95
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
          }
        }

        Component.onCompleted: showAnim.start()

        RowLayout {
          anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 16
          }
          spacing: 10

          Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.osdIcon
            color: root.osdColor
            font.pixelSize: 18
            font.family: root.font

            Behavior on color {
              ColorAnimation { duration: 150 }
            }
          }

          Rectangle {
            // Stretches to fill all left-over space
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            implicitHeight: 8
            radius: height / 2
            color: "#50ffffff"

            Rectangle {
              anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
              }

              implicitWidth: parent.width * root.osdValue
              radius: parent.radius
              color: root.osdColor

              Behavior on implicitWidth {
                NumberAnimation {
                  duration: 200
                  easing.type: Easing.OutCubic
                }
              }

              Behavior on color {
                ColorAnimation { duration: 150 }
              }
            }
          }

          Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
            text: root.osdValueText
            color: root.theme.textPrimary
            font.pixelSize: 12
            font.family: root.font
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }
}