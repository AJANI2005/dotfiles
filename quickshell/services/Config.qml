// Shared user configuration (terminal, etc).
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: cfg
  readonly property string terminal: "alacritty"
}