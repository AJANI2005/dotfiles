// Theme service: builds a dark palette from the current awww wallpaper.
// Add predefined schemes to `palettes` and they become selectable by name.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: theme

  // ---- predefined schemes (one for now; keys are valid `theme set` names) ----
  readonly property var fallback: ({
    bg: "#0b0b0f", surface: "#141419", raised: "#1c1c24", border: "#23232e",
    panel: "#d1141419", text: "#e6e7f0", dim: "#9aa0b5", faint: "#565a6e",
    accent: "#7aa2f7", good: "#9ece6a", warn: "#e0af68", bad: "#f7768e"
  })

  readonly property var palettes: ({
    obsidian: fallback
  })

  // "wallpaper" derives colors from the wallpaper; any key above is static.
  property string mode: "wallpaper"
  property string wallpaperPath: ""

  readonly property var c: mode === "wallpaper"
    ? (quantizer.colors.length > 1 ? buildPalette(quantizer.colors) : fallback)
    : (palettes[mode] || fallback)

  readonly property color bg: c.bg
  readonly property color surface: c.surface
  readonly property color raised: c.raised
  readonly property color border: c.border
  readonly property color panel: c.panel
  readonly property color text: c.text
  readonly property color dim: c.dim
  readonly property color faint: c.faint
  readonly property color accent: c.accent
  readonly property color good: c.good
  readonly property color warn: c.warn
  readonly property color bad: c.bad

  readonly property string font: "JetBrainsMono Nerd Font"
  readonly property int barHeight: 32
  readonly property int radius: 10
  readonly property int gap: 6
  readonly property int pad: 10

  // Resolve a themed icon without emitting a "could not load" warning when missing.
  function icon(name, fallback) {
    const f = fallback || "application-x-executable"
    return Quickshell.iconPath(name, true) || Quickshell.iconPath(f, true)
  }

  readonly property string modePath: Quickshell.statePath("theme")

  ColorQuantizer {
    id: quantizer
    source: theme.wallpaperPath === ""
      ? ""
      : "file://" + theme.wallpaperPath.split("/").map(encodeURIComponent).join("/")
    rescaleSize: 40
    depth: 4
  }

  Process {
    id: wallpaperQuery
    command: ["awww", "query", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: theme.loadWallpaper(text)
    }
  }

  Process {
    id: modeRead
    running: true
    command: ["sh", "-c", "cat '" + theme.modePath + "' 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: theme.loadMode(text)
    }
  }

  Process { id: modeWrite }

  Component.onCompleted: refresh()

  function refresh() {
    wallpaperQuery.running = false
    wallpaperQuery.running = true
  }

  function setWallpaper(path) {
    if (path) wallpaperPath = path
  }

  function loadWallpaper(text) {
    let path = ""
    try {
      const data = JSON.parse(String(text || "{}"))
      for (const ns in data) {
        const outs = data[ns]
        if (!Array.isArray(outs)) continue
        for (const o of outs) {
          if (o && o.displaying && o.displaying.image) { path = o.displaying.image; break }
        }
        if (path) break
      }
    } catch (e) { path = "" }
    if (path) setWallpaper(path)
  }

  function loadMode(text) {
    const t = String(text || "").trim()
    if (t === "wallpaper" || palettes[t]) mode = t
  }

  function saveMode() {
    modeWrite.command = ["sh", "-c",
      "mkdir -p '" + Quickshell.stateDir + "' && printf '%s' '" + mode + "' > '" + modePath + "'"]
    modeWrite.running = false
    modeWrite.running = true
  }

  // Pick dark/light extremes for backgrounds/text and the most vivid color for accent.
  function buildPalette(raw) {
    const lum = c => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
    const sat = c => {
      const mx = Math.max(c.r, c.g, c.b)
      const mn = Math.min(c.r, c.g, c.b)
      return mx <= 0 ? 0 : (mx - mn) / mx
    }
    const list = raw.slice().sort((a, b) => lum(a) - lum(b))
    const dark = list[0]
    const light = list[list.length - 1]
    let accent = list.slice().sort((a, b) => sat(b) - sat(a))[0]
    if (lum(accent) < 0.3) accent = Qt.lighter(accent, 1.7)
    const bg = Qt.darker(dark, 2.6)
    const surface = Qt.lighter(bg, 1.35)
    const fg = Qt.lighter(light, 1.35)
    return {
      bg: bg,
      surface: surface,
      raised: Qt.lighter(bg, 1.75),
      border: Qt.lighter(bg, 2.2),
      panel: Qt.rgba(surface.r, surface.g, surface.b, 0.82),
      text: fg,
      dim: mix(fg, bg, 0.35),
      faint: mix(fg, bg, 0.72),
      accent: accent,
      good: fallback.good,
      warn: fallback.warn,
      bad: fallback.bad
    }
  }

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }

  IpcHandler {
    target: "theme"
    function set(n: string): void {
      if (n === "wallpaper" || theme.palettes[n]) { theme.mode = n; theme.saveMode() }
    }
    function next(): void {
      const names = ["wallpaper"].concat(Object.keys(theme.palettes))
      const i = names.indexOf(theme.mode)
      theme.mode = names[(i + 1) % names.length]
      theme.saveMode()
    }
    function list(): string {
      return ["wallpaper"].concat(Object.keys(theme.palettes)).join(" ")
    }
    function current(): string { return theme.mode }
    function refresh(): void { theme.refresh() }
  }
}
