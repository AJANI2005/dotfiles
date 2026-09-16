import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root

    width: 18
    height: 16
    radius: height / 2

    color: Theme.bgColor

    Word {
        anchors.centerIn: parent

        text: Hyprland.focusedWorkspace?.id ?? 1
        color: Theme.accentColor

        font.pixelSize: 9
        font.bold: true
    }
}
