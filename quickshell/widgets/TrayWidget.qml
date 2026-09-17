// Bar component: system tray icons with their DBus menus.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
  id: root
  spacing: 4

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
          const it = slot.item
          const openMenu = () => {
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
