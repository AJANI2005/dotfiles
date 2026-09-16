import QtQuick
import "animations"

Rectangle {
  id: root

  // Date state
  property string timeText
  property int dayIndex
  property int dayNumber

  // Magic numbers
  property int baseWidth: 75
  property int baseHeight: 24
  property int expandedScale: 3
  property int expandedHeightScale: 4

  property bool hovered: false

  Proc {
    command: ["date", "+%H:%M|%w|%d"]
    interval: 1000
    callback: (text) => {
        let parts = text.trim().split("|")
        root.timeText = parts[0]
        root.dayIndex = parseInt(parts[1])
        root.dayNumber = parseInt(parts[2])
    }
  }

  x: parent.width / 2 - width / 2
  y: 2
  width: hovered ? baseWidth * expandedScale : baseWidth
  height: hovered ? baseHeight * expandedHeightScale : baseHeight
  radius: width / 2
  color: Theme.bgColor

  // Big View
  Column{
    x: parent.width / 2 - width / 2
    y: parent.height / 2 - height / 2
    spacing: 10

    // Time
    Word {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.timeText
      font.pixelSize: root.hovered ? 20 : Theme.defaultFontSize
      font.bold: true
      Behavior on font.pixelSize { NumberAnimation { duration: 50 }}
    }

    // Week View
    Row {
        visible: root.hovered
        opacity: root.hovered ? 1 : 0
        spacing: 10
        Repeater {
          model: 7
          Column{
            property list<string> days: ["SUN","MON","TUE","WED","THU","FRI","SAT"]
            property int day: (root.dayIndex + index - 3 + 7) % 7
            property bool cur: index == 3
            property int number: { let d = new Date(); d.setDate(d.getDate() + index - 3); return d.getDate() }

            Word {
                text: cur ? days[day] : days[day][0]
                font.bold: cur
                font.pixelSize: Theme.defaultFontSize * 0.8
                opacity: 1 - Math.abs(index - 3) * 0.3
                color: Theme.defaultTextColor
            }
            Word {
                anchors.horizontalCenter: parent.horizontalCenter
                text: number
                color: index == 3 ? Theme.accentColor : Theme.defaultTextColor
                font.bold: index == 3
                font.pixelSize: index == 3 ? Theme.defaultFontSize * 1.2  : Theme.defaultFontSize * 0.8

                opacity: 1 - Math.abs(index - 3) * 0.3
            }
          }
        }

        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }

  }

  MouseArea{ anchors.fill:parent; hoverEnabled: true;
  onEntered: root.hovered = true; onExited: root.hovered = false; }
  Behavior on width { Springy { duration: 150 }}
  Behavior on height { Springy { duration: 150 }}
}
