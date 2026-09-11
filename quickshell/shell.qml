import QtQuick
import Quickshell
import Quickshell.Wayland

// Main shell. The wallpaper carousel lives in Wallpapers.qml (exported type
// Wallpapers) and shares this process, so the IPC handler is reachable via:
//   qs ipc call wallpapers toggle

ShellRoot {
    id: root

    Wallpapers {}
}