// Workspace service: queries Hyprland workspace entities.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
  id: ws

  readonly property var values: Hyprland.workspaces.values
  readonly property var focused: Hyprland.focusedWorkspace

  function focus(id) {
    for (const w of values) {
      if (w.id === id) { w.activate(); return }
    }
    if (Hyprland.usingLua) Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")
    else Hyprland.dispatch("workspace " + id)
  }

  function isFocused(id) {
    return focused !== null && focused !== undefined && focused.id === id
  }

  function isOccupied(id) {
    for (const w of values) {
      if (w.id === id) return w.toplevels.values.length > 0
    }
    return false
  }
}
