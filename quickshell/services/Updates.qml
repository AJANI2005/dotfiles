// Update service: counts pacman + brew updates and launches the upgrade.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
  id: updates

  property int count: 0

  Process {
    id: poll
    command: ["sh", "-c",
      "p=$(pacman -Qu 2>/dev/null | wc -l); "
      + "a=$(paru -Qua 2>/dev/null | wc -l); "
      + "b=$(brew outdated -q 2>/dev/null | wc -l); "
      + "echo $((p + a + b))"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const n = parseInt(String(text).trim())
        updates.count = isNaN(n) ? 0 : n
      }
    }
  }

  Timer {
    interval: 1800000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: poll.running = true
  }

  Process {
    id: upgrade
    command: ["alacritty", "--hold", "-e", "bash", "-ic",
      "paru -Syu; brew update && brew upgrade; exec bash"]
  }

  function runUpgrade() {
    upgrade.running = false
    upgrade.running = true
  }
}
