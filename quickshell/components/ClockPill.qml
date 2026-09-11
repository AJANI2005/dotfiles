import QtQuick

Rectangle {
    id: root

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 22
    radius: 11
    color: "#16130f"
    border { width: 1; color: "#38332d" }

    Text {
        id: label
        anchors.centerIn: parent
        font.family: "0xProto Nerd Font"
        font.pixelSize: 12
        color: "#cfc7ba"
        text: Qt.formatTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: label.text = Qt.formatTime(new Date(), "HH:mm")
    }
}