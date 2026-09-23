pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property int updatesCount: 0
  property bool checking: false

  Process {
    id: checkProc
    command: ["sh", "-c", "paru -Qu | wc -l"]
    running: true

    stdout: StdioCollector {
      
      onStreamFinished: {
        const value = parseInt(text.trim());
        root.updatesCount = isNaN(value) ? 0 : value;
        root.checking = false;
      }
    }

    onExited: (exitCode, exitStatus) => root.checking = false
  }

  Process {
    id: updateProc
    command: ["alacritty", "-e", "paru", "-Syu"]
    running: false
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: (exitCode, exitStatus) => root.refresh()
  }
  Timer {
    interval: 300000
    running: true
    repeat: true
    onTriggered: { refresh(); }
  }

  function update() {
    updateProc.running = false;
    updateProc.running = true;
  }

  function refresh() {
    root.checking = true;
    checkProc.running = false;
    checkProc.running = true;
  }
  Component.onCompleted: { refresh(); }
}
