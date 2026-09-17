//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
// Composition root: bar on every screen, overlays on the focused screen.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

ShellRoot {
  id: shell

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

  AppLauncher { screen: shell.focusedScreen }
  WallpaperSwitcher { screen: shell.focusedScreen }
}
