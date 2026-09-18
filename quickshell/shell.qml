//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
// Composition root: bar on every screen, overlays on the focused screen.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs

ShellRoot {
  id: shell

  Component.onCompleted: Quickshell.watchFiles = true

  IpcHandler {
    target: "quickshell"
    function reload(): void { Quickshell.reload(true) }
  }

  readonly property var focusedScreen: {
    const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    const list = Quickshell.screens
    for (let i = 0; i < list.length; i++) {
      if (list[i].name === name) return list[i]
    }
    return list.length > 0 ? list[0] : null
  }

  Variants {
    model: Quickshell.screens
    Bar { property var modelData; screen: modelData }
  }

  WallpaperSwitcher { screen: shell.focusedScreen }
}
