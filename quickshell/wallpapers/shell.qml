import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Carousel wallpaper switcher modelled on omarchy's full-screen image picker.
// Standalone: no omarchy runtime, palette, or config files required.
//
// Launch it with:
//   qs -n -d -p "$HOME/.config/quickshell/wallpapers/shell.qml"
//
// IPC (quickshell's own ipc):
//   qs -p "$HOME/.config/quickshell/wallpapers/shell.qml" ipc call wallpapers toggle
//   qs -p "$HOME/.config/quickshell/wallpapers/shell.qml" ipc call wallpapers next
//   qs -p "$HOME/.config/quickshell/wallpapers/shell.qml" ipc call wallpapers prev
//   qs -p "$HOME/.config/quickshell/wallpapers/shell.qml" ipc call wallpapers pick 3
//   qs -p "$HOME/.config/quickshell/wallpapers/shell.qml" ipc call wallpapers apply
//
// Enter / click on the focused card applies the wallpaper via awww (the
// machine's wallpaper setter): `awww img -t random --transition-fps 144 -- <file>`.
ShellRoot {
    id: root

    // ---- theme ----
    readonly property color foreground: "#e9e6e1"
    readonly property color dimColor: "#16140f"
    readonly property color selectedBorder: "#e87962"
    readonly property color unselectedBorder: "#403d38"

    readonly property string wallDir: Quickshell.env("HOME") + "/wallpapers"

    readonly property int expandedWidth: 768
    readonly property int expandedHeight: 475
    readonly property int sliceWidth: 108
    readonly property int sliceHeight: 432
    readonly property int sliceSpacing: -30
    readonly property int skewOffset: 28
    readonly property int topChrome: 32
    readonly property int bottomChromeHeight: 42

    // ---- state ----
    property bool opened: false
    property bool imagesLoaded: false
    property bool layoutSettled: false
    property var imageArray: []
    property var folders: []
    property var folderImages: []
    property int currentDirIndex: 0
    property int selectedIndex: 0

    function fileUrl(path) {
        return "file://" + String(path || "").split("/").map(encodeURIComponent).join("/");
    }
    function alpha(color, a) {
        return Qt.rgba(color.r, color.g, color.b, a);
    }
    function nameForPath(path) {
        return String(path || "").split("/").pop().replace(/\.[^/.]+$/, "");
    }
    function labelForPath(path) {
        return nameForPath(path).replace(/[-_]+/g, " ").replace(/\b\w/g, function(m) { return m.toUpperCase(); });
    }
    function currentPath() {
        if (root.folderImages.length === 0) return "";
        return root.folderImages[root.selectedIndex].filePath;
    }
    function currentLabel() {
        return labelForPath(root.currentPath());
    }
    function currentFolderLabel() {
        if (root.folders.length === 0) return "";
        var dir = root.folders[root.currentDirIndex] || "";
        if (dir.indexOf(root.wallDir) === 0) return "~/wallpapers" + dir.substring(root.wallDir.length);
        return dir;
    }

    function select(index, immediate) {
        if (root.folderImages.length === 0) return;
        if (index < 0) index = 0;
        else if (index >= root.folderImages.length) index = root.folderImages.length - 1;
        if (index === root.selectedIndex && immediate !== true) return;
        root.selectedIndex = index;
    }
    function selectAdjacent(direction) {
        root.select(root.selectedIndex + direction);
    }
    function folderStep(direction) {
        if (root.folders.length === 0) return;
        var n = root.folders.length;
        root.currentDirIndex = (root.currentDirIndex + direction + n) % n;
        root.refold();
        root.selectedIndex = 0;
    }
    function openFolderByPath(dir) {
        var idx = root.folders.indexOf(dir);
        if (idx >= 0) {
            root.currentDirIndex = idx;
            root.refold();
        }
    }
    function refold() {
        var dir = root.folders.length > 0 ? root.folders[root.currentDirIndex] : "";
        var list = [];
        for (var i = 0; i < root.imageArray.length; i++) {
            if (root.imageArray[i].dir === dir) list.push(root.imageArray[i]);
        }
        root.folderImages = list;
        if (root.selectedIndex >= list.length) root.selectedIndex = list.length - 1;
        if (root.selectedIndex < 0) root.selectedIndex = 0;
    }

    function startAutoselect() {
        queryProc.running = false;
        queryProc.running = true;
    }
    function onQueryFinished(text) {
        var path = "";
        try {
            var data = JSON.parse(String(text || "{}"));
            for (var ns in data) {
                if (data.hasOwnProperty(ns)) {
                    var outputs = data[ns];
                    if (!Array.isArray(outputs)) continue;
                    for (var i = 0; i < outputs.length; i++) {
                        var disp = outputs[i] ? outputs[i].displaying : null;
                        if (disp && disp.image) { path = disp.image; break; }
                    }
                    if (path) break;
                }
            }
        } catch (e) { path = ""; }
        if (path) {
            var found = -1;
            for (var k = 0; k < root.imageArray.length; k++) {
                if (root.imageArray[k].filePath === path) { found = k; break; }
            }
            if (found >= 0) {
                root.openFolderByPath(root.imageArray[found].dir);
                for (var j = 0; j < root.folderImages.length; j++) {
                    if (root.folderImages[j].filePath === path) { root.selectedIndex = j; break; }
                }
            }
        }
        root.settle();
    }

    function open() {
        if (root.opened) return;
        root.opened = true;
        root.layoutSettled = false;
        if (!root.imagesLoaded) {
            listProc.running = false;
            listProc.running = true;
        } else {
            root.startAutoselect();
        }
    }
    function cancel() {
        if (!root.opened) return;
        root.opened = false;
        root.layoutSettled = false;
    }
    function toggle() {
        if (root.opened) root.cancel();
        else root.open();
    }

    function settle() {
        if (!root.opened || !root.imagesLoaded) return;
        root.layoutSettled = true;
        Qt.callLater(function() {
            if (root.opened && root.folderImages.length > 0)
                carousel.forceActiveFocus();
        });
    }

    function loadRows(text) {
        var images = [];
        var seen = {};
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var row = lines[i];
            if (!row) continue;
            var cols = row.split("\t");
            var path = cols[0];
            if (!path) continue;
            var name = path.split("/").pop();
            if (seen[name]) continue;
            seen[name] = true;
            var slash = path.lastIndexOf("/");
            images.push({
                filePath: path,
                fileName: name,
                thumbnailPath: cols[1] || path,
                dir: slash > 0 ? path.substring(0, slash) : "/"
            });
        }
        root.imageArray = images;
        var dirSet = {};
        for (var d = 0; d < images.length; d++) dirSet[images[d].dir] = true;
        var dirs = [];
        for (var dn in dirSet) if (dirSet.hasOwnProperty(dn)) dirs.push(dn);
        dirs.sort();
        root.folders = dirs;
        if (root.currentDirIndex >= dirs.length) root.currentDirIndex = 0;
        root.refold();
        root.selectedIndex = 0;
        root.layoutSettled = false;
        root.imagesLoaded = true;
        if (root.opened) root.startAutoselect();
    }

    function applySelected() {
        var path = root.currentPath();
        if (!path) return;
        applyProc.command = ["awww", "img", "-t", "random", "--transition-fps", "144", "--", path];
        applyProc.running = false;
        applyProc.running = true;
    }

    // ---- listing (absolute paths, one per line: path<TAB>thumb) ----
    Process {
        id: listProc
        running: true
        command: ["bash", "-lc",
              "D=\"$HOME/wallpapers\"; [ -d \"$D\" ] || exit 0; "
            + "find -L \"$D\" -type f "
            + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o "
            + "-iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) "
            + "-print0 2>/dev/null | sort -z | "
            + "while IFS= read -r -d '' f; do printf '%s\\t%s\\n' \"$f\" \"$f\"; done"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.loadRows(text || "")
        }
    }

    // ---- current wallpaper lookup ----
    Process {
        id: queryProc
        command: ["awww", "query", "-j"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.onQueryFinished(text || "")
        }
    }

    // ---- apply ----
    Process {
        id: applyProc
        onExited: {
            root.layoutSettled = false;
            root.opened = false;
        }
    }

    // Make sure the awww daemon is alive so `awww img` always has a target.
    Process {
        id: daemonUp
        running: true
        command: ["bash", "-lc",
              "pgrep -x awww-daemon >/dev/null 2>&1 || setsid awww-daemon >/dev/null 2>&1 &"]
    }

    // ---- IPC ----
    IpcHandler {
        target: "wallpapers"
        function show(): void          { root.open(); }
        function hide(): void          { root.cancel(); }
        function toggle(): void        { root.toggle(); }
        function next(): void          { root.selectAdjacent(1); }
        function prev(): void          { root.selectAdjacent(-1); }
        function pick(i: int): void    { root.select(i, true); }
        function apply(): void         { root.applySelected(); }
        function count(): int          { return root.folderImages.length; }
        function filename(): string    {
            return root.folderImages.length > 0 ? root.folderImages[root.selectedIndex].fileName : "";
        }
    }

    // ---- surface ----
    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "qs-wallpapers"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened && root.imagesLoaded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Click anywhere outside the deck to dismiss.
        MouseArea {
            anchors.fill: parent
            enabled: root.opened && root.imagesLoaded
            onClicked: root.cancel()
        }

        // Empty state (visible for diagnostics when the scan finds nothing).
        Text {
            anchors.centerIn: parent
            visible: root.opened && root.imagesLoaded && root.imageArray.length === 0
            text: "no wallpapers in " + root.wallDir
            color: root.alpha(root.foreground, 0.55)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        Item {
            id: card
            visible: root.opened && root.imagesLoaded && root.layoutSettled && root.folderImages.length > 0
            width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
            height: root.expandedHeight + root.topChrome + root.bottomChromeHeight
            anchors.centerIn: parent

            MouseArea { anchors.fill: parent; onClicked: {} }

            // current folder breadcrumb
            Text {
                id: folderLabel
                anchors.top: parent.top
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentFolderLabel()
                color: root.alpha(root.foreground, 0.9)
                style: Text.Outline
                styleColor: root.alpha(root.dimColor, 0.7)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Item {
                id: carousel
                anchors.top: parent.top
                anchors.topMargin: root.topChrome
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.bottomChromeHeight
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
                clip: false
                focus: true

                readonly property real itemStep: root.sliceWidth + root.sliceSpacing
                readonly property real previewX: (width - root.expandedWidth) / 2

                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applySelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab
                               || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                        root.selectAdjacent(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        root.selectAdjacent(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        root.folderStep(-1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        root.folderStep(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Home) {
                        root.selectedIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_End) {
                        root.selectedIndex = root.folderImages.length - 1;
                        event.accepted = true;
                    }
                }

                Repeater {
                    model: root.folderImages.length

                    delegate: Item {
                        id: item
                        required property int index

                        readonly property var imageData: root.folderImages[index]
                        readonly property string filePath: imageData ? imageData.filePath : ""
                        readonly property string thumbnailPath: imageData ? imageData.thumbnailPath : ""

                        readonly property bool selected: index === root.selectedIndex
                        readonly property int relativeIndex: index - root.selectedIndex
                        readonly property bool nearby: Math.abs(relativeIndex) <= 12
                        property bool sourceActivated: nearby
                        onNearbyChanged: if (nearby) sourceActivated = true

                        visible: nearby
                        x: selected ? carousel.previewX
                           : (relativeIndex < 0
                                ? carousel.previewX + relativeIndex * carousel.itemStep
                                : carousel.previewX + root.expandedWidth + root.sliceSpacing
                                  + (relativeIndex - 1) * carousel.itemStep)
                        width: selected ? root.expandedWidth : root.sliceWidth
                        height: selected ? root.expandedHeight : root.sliceHeight
                        y: selected ? 0 : (root.expandedHeight - root.sliceHeight) / 2
                        z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

                        readonly property real skAbs: Math.abs(root.skewOffset)
                        readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
                        readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
                        readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
                        readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

                        Item {
                            id: maskShape
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true

                            Shape {
                                anchors.fill: parent
                                antialiasing: true
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    fillColor: "white"
                                    strokeColor: "transparent"
                                    startX: item.topLeft; startY: 0
                                    PathLine { x: item.topRight; y: 0 }
                                    PathLine { x: item.bottomRight; y: item.height }
                                    PathLine { x: item.bottomLeft; y: item.height }
                                    PathLine { x: item.topLeft; y: 0 }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            layer.enabled: true
                            layer.smooth: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: maskShape
                                maskThresholdMin: 0.3
                                maskSpreadAtMin: 0.3
                            }

                            Image {
                                id: image
                                anchors.fill: parent
                                source: item.sourceActivated && item.thumbnailPath ? root.fileUrl(item.thumbnailPath) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(1200, 900)
                                cache: true
                                smooth: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.alpha(root.dimColor, item.selected ? 0 : 0.42)
                            }
                        }

                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: item.selected ? root.selectedBorder : root.unselectedBorder
                                strokeWidth: item.selected ? 3 : 1
                                startX: item.topLeft; startY: 0
                                PathLine { x: item.topRight; y: 0 }
                                PathLine { x: item.bottomRight; y: item.height }
                                PathLine { x: item.bottomLeft; y: item.height }
                                PathLine { x: item.topLeft; y: 0 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: item.selected ? root.applySelected() : root.select(item.index)
                        }
                    }
                }
            }

            // current wallpaper label, below the deck
            Text {
                id: selectedLabel
                visible: root.folderImages.length > 0
                text: root.currentLabel()
                textFormat: Text.PlainText
                anchors.top: carousel.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: carousel.horizontalCenter
                width: root.expandedWidth
                color: root.foreground
                style: Text.Outline
                styleColor: root.alpha(root.dimColor, 0.7)
                font.pixelSize: 15
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
