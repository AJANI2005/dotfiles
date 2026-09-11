import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var command: []
    property var parser: null
    property int interval: 0
    property var value: null

    function run() { process.running = true }

    Process {
        id: process
        command: root.command

        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                root.value = root.parser ? root.parser(data) : data.trim()
            }
        }
    }

    Timer {
        id: timer
        interval: root.interval
        repeat: true
        running: root.interval > 0 && root.command.length > 0
        triggeredOnStart: true

        onTriggered: process.running = true
    }
}
