//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
  id: r

  // Magic numbers
  property int barHeight: 24
  property int windowHeight: 200

  // Wallpaper Switcher
  WallpaperSwitcher{}

  // Main Window
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: w
      required property var modelData
      screen: modelData

      anchors { top: true; left: true; right: true; }
      color: "transparent"
      implicitHeight: r.windowHeight

      exclusiveZone: r.barHeight

      property Item activeItem: null

      mask: Region { item: clickRegion }
      Rectangle {
        id: clickRegion
        // color: "#22ffffff" 
        color: "transparent"
        x: activeItem?.x ?? 0
        y: activeItem?.y ?? 0
        width: activeItem?.width ??  w.screen.width
        height: activeItem?.height ?? r.barHeight
      }
      

      component HoverDetector : MouseArea { 
          anchors.fill:parent; hoverEnabled: true;
          onEntered: { parent.hovered = true; activeItem = parent }  
          onExited: { parent.hovered = false; activeItem = null }
      }


      // Clock Pill
      Clock {
        id: clock
        HoverDetector{}
      }
      Workspaces{ 
        x: clock.x - width - 5; y: clock.y + 10 
        HoverDetector{}
      }
    }
  }

}
