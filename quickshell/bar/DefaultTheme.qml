import QtQuick

QtObject {
  readonly property color bgBase: "#000000"
  readonly property color bgSurface: "#0a0a0a"
  readonly property color bgOverlay: "#00000000"
  readonly property color bgHover: "#111111"
  readonly property color bgSelected: "#161616"
  readonly property color bgBorder: "#161616"

  readonly property color textPrimary: "#e6e6e6"
  readonly property color textSecondary: "#a3a3a3"
  readonly property color textMuted: "#5c5c5c"

  readonly property color accentPrimary: "#7aa2f7"
  readonly property color accentCyan: "#7dcfff"
  readonly property color accentGreen: "#9ece6a"
  readonly property color accentOrange: "#ff9e64"
  readonly property color accentRed: "#f7768e"

  readonly property color urgencyLow: textMuted
  readonly property color urgencyNormal: accentPrimary
  readonly property color urgencyCritical: accentRed
  readonly property color batteryGood: accentGreen
  readonly property color batteryWarning: accentOrange
  readonly property color batteryCritical: accentRed

}
