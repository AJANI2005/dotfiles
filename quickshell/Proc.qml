import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var callback;
  property list<string> command
  property int interval: 5000
  Process {
    id: proc; running: true; command: root.command;
    stdout: StdioCollector { onStreamFinished: { root.callback(text) } }
  }
  Timer { interval: root.interval; running: true; repeat: true; onTriggered: { proc.running=true; } }
}