// App launcher: centered rectangle with a search field and a row list of apps.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs

PanelWindow {
  id: root

  property bool open: false
  property string query: ""
  property string pendingQuery: ""
  readonly property var results: Apps.query(query)
  readonly property int wheelStep: 40
  readonly property int fontSize: 18

  Timer {
    id: searchDebounce
    interval: 120
    onTriggered: root.query = root.pendingQuery
  }

  visible: open
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "qs-launcher"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  IpcHandler {
    target: "launcher"
    function toggle(): void { root.open = !root.open }
    function show(): void { root.open = true }
    function hide(): void { root.open = false }
  }

  onOpenChanged: {
    if (open) {
      input.text = ""
      searchDebounce.stop()
      query = ""
      pendingQuery = ""
      list.selected = 0
      Qt.callLater(() => input.forceActiveFocus())
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.open = false
  }

  Rectangle {
    id: card
    width: Math.min(parent.width - 64, 400)
    height: Math.min(parent.height - 96, 620)
    anchors.centerIn: parent
    radius: 2
    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.72)
    border.color: Theme.accent
    border.width: 3

    MouseArea { anchors.fill: parent }

    Column {
      anchors.fill: parent
      anchors.margins: Theme.pad
      spacing: Theme.gap

      TextInput {
        id: input
        width: parent.width
        height: 34
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: root.fontSize
        selectionColor: Theme.accent
        selectedTextColor: Theme.bg
        onTextChanged: {
          root.pendingQuery = text
          list.selected = 0
          searchDebounce.restart()
        }

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          visible: input.text.length === 0
          text: "Apps:"
          color: Theme.dim
          font.family: Theme.font
          font.pixelSize: root.fontSize
        }

        Keys.onEscapePressed: root.open = false
        Keys.onDownPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
        Keys.onReturnPressed: root.launch(list.selected)
        Keys.onPressed: (event) => {
          if (!(event.modifiers & Qt.ControlModifier)) return
          if (event.key === Qt.Key_J) { root.move(1); event.accepted = true }
          else if (event.key === Qt.Key_K) { root.move(-1); event.accepted = true }
        }
      }

      ListView {
        id: list
        width: parent.width
        height: parent.height - input.height - Theme.gap
        clip: true
        model: root.results
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 8000
        property real wheelAccum: 0
        property int selected: 0

        WheelHandler {
          onWheel: (event) => {
            const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y
            list.wheelAccum += dy
            while (list.wheelAccum <= -root.wheelStep) {
              root.move(-1)
              list.wheelAccum += root.wheelStep
            }
            while (list.wheelAccum >= root.wheelStep) {
              root.move(1)
              list.wheelAccum -= root.wheelStep
            }
            event.accepted = true
          }
        }

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: list.width
          height: 56
          radius: 4
          color: index === list.selected
            ? Qt.rgba(Theme.raised.r, Theme.raised.g, Theme.raised.b, 0.5)
            : "transparent"

          Image {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            source: Theme.icon(modelData.icon)
            sourceSize: Qt.size(34, 34)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
          }

          Text {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.name
            color: index === list.selected ? Theme.text : Theme.dim
            font.family: Theme.font
            font.pixelSize: root.fontSize
            font.bold: index === list.selected
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.launch(index)
          }
        }
      }
    }
  }

  function move(delta) {
    if (list.count === 0) return
    list.selected = Math.max(0, Math.min(list.count - 1, list.selected + delta))
    list.positionViewAtIndex(list.selected, ListView.Contain)
  }

  function launch(index) {
    searchDebounce.stop()
    if (pendingQuery !== query) query = pendingQuery
    const entry = results[index]
    if (!entry) return
    Apps.launch(entry)
    root.open = false
  }
}
