import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property string valueColor: "#cfc7ba"

    width: 300
    height: 26

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        font.family: "0xProto Nerd Font"
        font.pixelSize: 14
        color: "#8a8378"
        text: root.icon
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 24
        font.family: "0xProto Nerd Font"
        font.pixelSize: 12
        color: "#8a8378"
        text: root.label
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        font.family: "0xProto Nerd Font"
        font.pixelSize: 12
        color: root.valueColor
        text: root.value
    }
}