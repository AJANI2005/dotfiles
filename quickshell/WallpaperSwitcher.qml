// Wallpaper switcher: overlapping parallelogram carousel with a center preview.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs

PanelWindow {
  id: root

  property bool open: false
  property int selectedIndex: 0
  property int currentDirIndex: 0

  readonly property var folders: {
    const seen = ({})
    const out = []
    for (let i = 0; i < Wallpapers.images.length; i++) {
      const p = String(Wallpapers.images[i])
      const dir = p.substring(0, p.lastIndexOf("/"))
      if (!seen[dir]) { seen[dir] = true; out.push(dir) }
    }
    out.sort()
    return out
  }

  readonly property string currentDir: folders.length > 0
    ? folders[Math.min(currentDirIndex, folders.length - 1)]
    : ""

  readonly property var folderImages: currentDir === ""
    ? []
    : Wallpapers.images.filter(p => String(p).substring(0, String(p).lastIndexOf("/")) === currentDir)

  readonly property int expandedWidth: 768
  readonly property int expandedHeight: 475
  readonly property int sliceWidth: 108
  readonly property int sliceHeight: 432
  readonly property int sliceSpacing: -30
  readonly property int skewOffset: 28
  readonly property int maxSlices: 7
  readonly property real itemStep: sliceWidth + sliceSpacing
  readonly property int deckWidth: expandedWidth + 13 * itemStep + 40
  readonly property int deckHeight: expandedHeight + 74

  visible: open
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "qs-wallpapers"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  IpcHandler {
    target: "wallpapers"
    function toggle(): void { root.open = !root.open }
    function show(): void { root.open = true }
    function hide(): void { root.open = false }
    function apply(): void { root.applyCurrent() }
    function next(): void { root.step(1) }
    function prev(): void { root.step(-1) }
  }

  onOpenChanged: {
    if (open) {
      Wallpapers.rescan()
      syncCurrent()
      Qt.callLater(() => carousel.forceActiveFocus())
    }
  }

  Connections {
    target: Wallpapers
    function onImagesChanged() { root.syncCurrent() }
    function onCurrentChanged() { root.syncCurrent() }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.open = false
  }

  Item {
    id: card
    width: Math.min(parent.width - 64, root.deckWidth)
    height: Math.min(parent.height - 96, root.deckHeight)
    anchors.centerIn: parent

    MouseArea { anchors.fill: parent }

    Text {
      id: label
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Theme.pad
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideMiddle
      text: {
        const p = root.folderImages[root.selectedIndex]
        return p ? String(p).split("/").pop() : ""
      }
      color: Theme.text
      font.family: Theme.font
      font.pixelSize: 14
    }

    Item {
      id: carousel
      anchors.top: parent.top
      anchors.bottom: label.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: Theme.pad
      anchors.bottomMargin: Theme.gap
      anchors.leftMargin: Theme.pad
      anchors.rightMargin: Theme.pad
      clip: true
      focus: true

      readonly property int count: root.folderImages.length
      readonly property real previewX: (width - root.expandedWidth) / 2

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
          root.open = false
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.applyCurrent()
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.step(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.step(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.folderStep(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.folderStep(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Home) {
          root.selectedIndex = 0
          event.accepted = true
        } else if (event.key === Qt.Key_End) {
          root.selectedIndex = carousel.count - 1
          event.accepted = true
        }
      }

      Repeater {
        model: root.folderImages.length

        delegate: Item {
          id: cell
          required property int index

          readonly property int relativeIndex: index - root.selectedIndex
          readonly property bool selected: relativeIndex === 0
          readonly property bool nearby: Math.abs(relativeIndex) <= root.maxSlices + 1

          readonly property real skAbs: Math.abs(root.skewOffset)
          readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
          readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
          readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
          readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

          visible: nearby
          opacity: image.status === Image.Ready ? 1 : 0

          x: selected
            ? carousel.previewX
            : relativeIndex < 0
              ? carousel.previewX + relativeIndex * root.itemStep
              : carousel.previewX + root.expandedWidth + root.sliceSpacing
                + (relativeIndex - 1) * root.itemStep
          y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
          width: selected ? root.expandedWidth : root.sliceWidth
          height: selected ? root.expandedHeight : root.sliceHeight
          z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

          Item {
            id: maskShape
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                startX: cell.topLeft
                startY: 0
                PathLine { x: cell.topRight; y: 0 }
                PathLine { x: cell.bottomRight; y: cell.height }
                PathLine { x: cell.bottomLeft; y: cell.height }
                PathLine { x: cell.topLeft; y: 0 }
              }
            }
          }

          Item {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: maskShape
              maskThresholdMin: 0.3
              maskSpreadAtMin: 0.3
            }

            Image {
              id: image
              anchors.fill: parent
              source: cell.nearby ? Wallpapers.fileUrl(root.folderImages[cell.index]) : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              sourceSize: Qt.size(900, 560)
              cache: true
              smooth: true
            }

            Rectangle {
              anchors.fill: parent
              color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, cell.selected ? 0 : 0.42)
            }
          }

          Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
              fillColor: "transparent"
              strokeColor: cell.selected ? Theme.accent : "transparent"
              strokeWidth: cell.selected ? 3 : 0
              startX: cell.topLeft
              startY: 0
              PathLine { x: cell.topRight; y: 0 }
              PathLine { x: cell.bottomRight; y: cell.height }
              PathLine { x: cell.bottomLeft; y: cell.height }
              PathLine { x: cell.topLeft; y: 0 }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.selected ? root.applyCurrent() : root.selectedIndex = cell.index
          }
        }
      }
    }
  }

  function step(delta) {
    const n = folderImages.length
    if (!n) return
    selectedIndex = Math.max(0, Math.min(n - 1, selectedIndex + delta))
  }

  function folderStep(delta) {
    const n = folders.length
    if (!n) return
    currentDirIndex = (currentDirIndex + delta + n) % n
    selectedIndex = 0
  }

  function syncCurrent() {
    const cur = Wallpapers.current
    if (!cur) return
    const dir = String(cur).substring(0, String(cur).lastIndexOf("/"))
    const di = folders.indexOf(dir)
    if (di < 0) return
    currentDirIndex = di
    let i = -1
    let n = 0
    for (let k = 0; k < Wallpapers.images.length; k++) {
      const p = String(Wallpapers.images[k])
      if (p.substring(0, p.lastIndexOf("/")) !== dir) continue
      if (p === cur) { i = n; break }
      n++
    }
    if (i >= 0) selectedIndex = i
  }

  function applyCurrent() {
    const path = folderImages[selectedIndex]
    if (!path) return
    Wallpapers.apply(path)
    root.open = false
  }
}
