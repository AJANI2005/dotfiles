// Bar component: system tray icons with their DBus menus behind a single toggle.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
  id: root
  implicitWidth: 20
  implicitHeight: 20

  property bool expanded: false

  onExpandedChanged: {
    if (root.expanded) inactivity.start()
    else inactivity.stop()
  }

  Timer {
    id: inactivity
    interval: 10000
    repeat: false
    onTriggered: root.expanded = false
  }

  Row {
    id: iconsRow
    spacing: 4
    visible: root.expanded || opacity > 0
    opacity: root.expanded ? 1 : 0
    anchors.right: toggle.left
    anchors.rightMargin: 6
    anchors.verticalCenter: toggle.verticalCenter

    Behavior on opacity {
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Repeater {
      model: SystemTray.items

      delegate: Item {
        id: slot
        required property var modelData
        readonly property var item: modelData

        width: 20
        height: 20
        anchors.verticalCenter: parent.verticalCenter

        Image {
          anchors.fill: parent
          anchors.margins: 2
          source: slot.item.icon
          sourceSize: Qt.size(16, 16)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
        }

        QsMenuAnchor {
          id: menu
          menu: slot.item.menu
          anchor.window: slot.QsWindow.window
          anchor.edges: Edges.Top | Edges.Left
          anchor.gravity: Edges.Top
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onEntered: inactivity.restart()
          onClicked: (mouse) => {
            inactivity.restart()
            const it = slot.item
            const openMenu = () => {
              inactivity.stop()
              const pos = slot.mapToItem(slot.QsWindow.contentItem, 0, 0)
              menu.anchor.rect.x = pos.x
              menu.anchor.rect.y = pos.y
              menu.anchor.rect.width = slot.width
              menu.anchor.rect.height = slot.height
              menu.open()
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

  Text {
    id: toggle
    anchors.centerIn: parent
    text: root.expanded ? "" : ""
    color: "#9aa0b5"
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      inactivity.restart()
      root.expanded = !root.expanded
    }
  }
}