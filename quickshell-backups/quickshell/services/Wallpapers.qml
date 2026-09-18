// Wallpaper service: scans ~/wallpapers and applies via awww with no transition.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
  id: store

  property var images: []
  property string current: ""
  property int index: 0

  Process {
    id: scan
    command: ["sh", "-c",
      "D=\"$HOME/wallpapers\"; [ -d \"$D\" ] || exit 0; "
      + "find -L \"$D\" -type f "
      + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o "
      + "-iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \\) "
      + "2>/dev/null | sort"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: store.setImages(text)
    }
  }

  Process {
    id: query
    command: ["awww", "query", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: store.setCurrent(text)
    }
  }

  Process {
    id: applyProc
    onExited: Qt.callLater(store.refreshCurrent)
  }

  Process {
    id: daemon
    running: true
    command: ["sh", "-c", "pgrep -x awww-daemon >/dev/null 2>&1 || setsid awww-daemon >/dev/null 2>&1 &"]
  }

  function rescan() {
    scan.running = false
    scan.running = true
  }

  function setImages(text) {
    images = String(text || "").split("\n").filter(l => l.length > 0)
    if (index >= images.length) index = Math.max(0, images.length - 1)
    refreshCurrent()
  }

  function refreshCurrent() {
    query.running = false
    query.running = true
  }

  function setCurrent(text) {
    try {
      const data = JSON.parse(String(text || "{}"))
      for (const ns in data) {
        const outs = data[ns]
        if (!Array.isArray(outs)) continue
        for (const o of outs) {
          if (o && o.displaying && o.displaying.image) {
            current = o.displaying.image
            const i = images.indexOf(current)
            if (i >= 0) index = i
            return
          }
        }
      }
    } catch (e) {}
  }

  function apply(path) {
    if (!path) return
    current = path
    Theme.setWallpaper(path)
    applyProc.command = ["awww", "img",
      "--transition-type", "random",
      "--transition-duration", "1.2",
      "--transition-fps", "144",
      "--", path]
    applyProc.running = false
    applyProc.running = true
  }

  function next() { if (images.length) index = Math.min(index + 1, images.length - 1) }
  function prev() { if (images.length) index = Math.max(index - 1, 0) }

  function fileUrl(path) {
    return "file://" + String(path || "").split("/").map(encodeURIComponent).join("/")
  }
}
