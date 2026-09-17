// Shared bar visibility, so every monitor toggles together via one IPC target.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: bar
  property bool visible: true

  IpcHandler {
    target: "bar"
    function toggle(): void { bar.visible = !bar.visible }
    function show(): void { bar.visible = true }
    function hide(): void { bar.visible = false }
  }
}
