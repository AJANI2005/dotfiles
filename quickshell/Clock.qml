import QtQuick
import "animations"

Rectangle {
  id: root

  property string timeText
  property int dayIndex
  property int dayNumber

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

  Column {
    x: parent.width / 2 - width / 2
    y: parent.height / 2 - height / 2
    spacing: 10

    Word {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.timeText
      font.pixelSize: root.hovered ? 20 : Theme.defaultFontSize
      font.bold: true

      Behavior on font.pixelSize {
        NumberAnimation { duration: 50 }
      }
    }

    Row {
      visible: root.hovered
      opacity: root.hovered ? 1 : 0
      spacing: 10

      Repeater {
        model: 7

        Column {
          property list<string> days: [
            "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"
          ]

          property int offset: index - 3

          property var date: {
            let d = new Date()
            d.setDate(d.getDate() + offset)
            return d
          }

          property int day: date.getDay()
          property int number: date.getDate()
          property bool cur: offset === 0

          Word {
            text: cur ? days[day] : days[day][0]
            font.bold: cur
            font.pixelSize: Theme.defaultFontSize * 0.8
            opacity: 1 - Math.abs(offset) * 0.3
            color: Theme.defaultTextColor
          }

          Word {
            anchors.horizontalCenter: parent.horizontalCenter

            text: number
            color: cur
                ? Theme.accentColor
                : Theme.defaultTextColor

            font.bold: cur
            font.pixelSize: cur
                ? Theme.defaultFontSize * 1.2
                : Theme.defaultFontSize * 0.8

            opacity: 1 - Math.abs(offset) * 0.3
          }
        }
      }

      Behavior on opacity {
        NumberAnimation { duration: 250 }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true

    onEntered: root.hovered = true
    onExited: root.hovered = false
  }

  Behavior on width {
    Springy { duration: 150 }
  }

  Behavior on height {
    Springy { duration: 150 }
  }
}
