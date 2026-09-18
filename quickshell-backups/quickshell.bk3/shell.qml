//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

ShellRoot {
  id: root

  // ---- professional clean high-contrast palette ----
  readonly property color bg: '#0f0f14'
  readonly property color panelBg: '#cc121218'
  readonly property color fg: '#cbd5e1'
  readonly property color activeFg: '#ffffff'
  readonly property color occupied: '#94a3b8'
  readonly property color dim: '#64748b'
  readonly property color border: 'transparent'
  readonly property color accent: '#ffffff'
  readonly property color accentDim: 'transparent'
  property int updateCount: 0

  function batteryColor(pct, charging) {
    if (charging) return root.fg
    if (pct >= 60) return root.fg
    if (pct >= 30) return root.occupied
    return root.dim
  }

  function workspace(id) {
    const list = Hyprland.workspaces.values
    for (const w of list) {
      if (w.id === id) return w
    }
    return null
  }

  // Wallpaper Switcher
  WallpaperSwitcher{}

  // Bar
  PanelWindow {
    id: bar
    property bool visibleBar: true

    visible: visibleBar
    anchors {
      bottom: true
      left: true
      right: true
    }
    height: 20
    color: "#660b0b0f"

    IpcHandler {
        target: "bar"
        function show(): void          { bar.visibleBar = true; }
        function hide(): void          { bar.visibleBar = false; }
        function toggle(): void        { bar.visibleBar = !bar.visibleBar; }
    }

    // Removed top border line
    Item {
      width: 1
      height: 1
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      spacing: 8

      // Workspaces with neat rounded pill badges
      Row {
        spacing: 4
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 4

        Row {
          spacing: 3
          Layout.alignment: Qt.AlignVCenter
          Repeater {
            model: 9

            Rectangle {
              required property int index
              readonly property int wsId: index + 1
              readonly property var wsObj: root.workspace(wsId)
              readonly property bool isFocused: Hyprland.focusedWorkspace !== null
              && Hyprland.focusedWorkspace.id === wsId
              readonly property bool isOccupied: wsObj !== null
              && wsObj.toplevels.values.length > 0

              width: 16
              height: 18
              radius: 0
              color: "transparent"
              border.color: "transparent"
              border.width: 0
              Layout.alignment: Qt.AlignVCenter

              // Removed width animation for snappy, zero-choppiness performance

              Text {
                anchors.centerIn: parent
                text: parent.wsId
                color: parent.isFocused
                ? root.activeFg
                : (parent.isOccupied ? root.fg : root.dim)
                font.pixelSize: 10
                font.bold: parent.isFocused
                font.family: "JetBrainsMono Nerd Font"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + parent.wsId)
              }
            }
          }
        }
      }

      // Window title / active app
      Item {
        Layout.fillWidth: true
    implicitHeight: 24

      }
      // System tray inside the TUI bar
      Row {
        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        Repeater {
          model: SystemTray.items

            Rectangle {
            id: trayDelegate
            required property var modelData
            readonly property var trayItem: modelData

            width: 20
            height: 18
            color: "transparent"
            border.color: "transparent"
            border.width: 0
            Layout.alignment: Qt.AlignVCenter

            Image {
              anchors.centerIn: parent
              width: 12
              height: 12
              source: parent.trayItem.icon
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            QsMenuAnchor {
              id: trayMenu
              menu: trayDelegate.trayItem.menu
              anchor.window: bar
              anchor.edges: Edges.Top | Edges.Left
              anchor.gravity: Edges.Top
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: (mouse) => {
                const it = parent.trayItem
                const openMenu = () => {
                  const pos = parent.mapToItem(bar.contentItem, 0, 0)
                  trayMenu.anchor.rect.x = pos.x
                  trayMenu.anchor.rect.y = pos.y
                  trayMenu.anchor.rect.width = parent.width
                  trayMenu.anchor.rect.height = parent.height
                  trayMenu.open()
                }
                if (mouse.button === Qt.RightButton) {
                  if (it.menu) openMenu()
                  else it.secondaryActivate()
                } else if (it.onlyMenu && it.menu) {
                  openMenu()
                } else {
                  it.activate()
                }
              }
            }
          }
        }
      }

      // Status widgets in a clean rounded container with subtle border
      Rectangle {
        height: 22
        radius: 11
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 4
        implicitWidth: clockRow.implicitWidth + 24
        color: "transparent"
        border.color: "transparent"
        border.width: 0

        RowLayout {
          id: clockRow
          anchors.centerIn: parent
          spacing: 10

          Text {
            id: updateText
            text: "upd:" + root.updateCount
            color: root.updateCount > 0 ? root.accent : root.dim
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                updateProc.running = true
                updateLaunch.startDetached()
              }
            }
          }

          Text {
            text: "·"
            color: root.dim
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }

          Item {
            id: batteryCell
            readonly property bool batteryReady: UPower.displayDevice !== null
            readonly property bool isCharging: batteryReady
            && (UPower.displayDevice.state === UPowerDeviceState.Charging
            || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
            readonly property int pct: batteryReady ? Math.round(UPower.displayDevice.percentage * 100) : 0

            width: batteryRow.implicitWidth
            height: 20
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
              id: batteryRow
              anchors.verticalCenter: parent.verticalCenter
              spacing: 4

              Row {
                Layout.alignment: Qt.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Repeater {
                  model: 8

                  Rectangle {
                    required property int index
                    Layout.alignment: Qt.AlignVCenter

                    width: 3
                    height: 10
                    color: index < Math.ceil(batteryCell.pct / 12.5)
                    ? (batteryCell.isCharging ? root.accent : root.fg)
                    : root.dim
                    border.color: "transparent"
                    border.width: 0
                  }
                }
              }

              Text {
                text: (batteryCell.isCharging ? "+" : "") + batteryCell.pct + "%"
                color: batteryCell.isCharging ? root.accent : root.fg
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
          }

          Text {
            text: "·"
            color: root.dim
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            id: dateText
            color: root.dim
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            text: "·"
            color: root.dim
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }

          Text {
            id: timeText
            color: root.activeFg
            font.pixelSize: 10
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Timer {
          interval: 1000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: {
            let d = new Date()
            dateText.text = Qt.formatDateTime(d, "MM-dd")
            timeText.text = Qt.formatDateTime(d, "hh:mm:ss")
          }
        }
      }
    }

    Timer {
      interval: 60000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: updateProc.running = true
    }

    Process {
        id: updateProc
        command: ["sh", "-c", "p=$(checkupdates 2>/dev/null | wc -l); b=$(brew outdated 2>/dev/null | tail -n +2 | wc -l); echo $((p + b))"]
        stdout: StdioCollector {
            id: updateCollector
            onStreamFinished: {
                const t = updateCollector.text.trim()
                root.updateCount = t === "" ? 0 : parseInt(t)
            }
        }
    }

    Process {
        id: updateLaunch
        command: ["foot", "--hold", "bash", "-ic", "paru -Syu; brew update; brew upgrade; exec bash"]
    }
  }
}
