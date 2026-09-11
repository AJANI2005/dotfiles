import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root

    property bool open: hoverCount > 0
    property int hoverCount: 0
    property var now: new Date()
    property var window: null

    property alias sensor: sensor
    property alias body: bodyPanel

    width: 324
    height: bodyPanel.height

    // Brightness — sysfs via FileView, event-driven (no per-second polling)
    property string backlightPath: ""
    property int brMax: 0
    property int brCurrent: 0
    property real brightness: brMax > 0 ? brCurrent * 100 / brMax : -1

    // Volume — Pipewire service (audio only valid while tracked, hence PwObjectTracker)
    readonly property PwNode pwSink: Pipewire.defaultAudioSink
    readonly property bool volumeMuted: root.pwSink && root.pwSink.audio ? root.pwSink.audio.muted : false
    readonly property real volume: root.pwSink && root.pwSink.audio ? root.pwSink.audio.volume : 0

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // Battery — UPower service (devices[] are always ready, unlike displayDevice)
    readonly property var upBat: {
        const list = UPower.devices ? UPower.devices.values : []
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].isLaptopBattery) return list[i]
        }
        return null
    }
    readonly property bool batReady: upBat != null
    readonly property int batPercent: upBat
        ? Math.round(upBat.percentage <= 1 ? upBat.percentage * 100 : upBat.percentage)
        : -1
    readonly property bool batCharging: upBat && upBat.state === UPowerDeviceState.Charging

    // Bluetooth — BlueZ service
    readonly property bool btPowered: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property string btName: {
        const list = Bluetooth.devices ? Bluetooth.devices.values : []
        for (var i = 0; i < list.length; i++) {
            const d = list[i]
            if (d && d.connected && d.name) return d.name
        }
        return ""
    }

    // Wifi — NetworkManager service
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool wifiLoaded: false

    // Hypridle toggle
    property bool idleRunning: false

    function refreshWifi() {
        root.wifiLoaded = true
        root.wifiSsid = ""
        root.wifiSignal = 0
        const devs = Networking.devices ? Networking.devices.values : []
        for (var i = 0; i < devs.length; i++) {
            const dev = devs[i]
            if (!dev || !dev.connected) continue
            if (dev.type !== DeviceType.Wifi) continue
            const nets = dev.networks ? dev.networks.values : []
            for (var j = 0; j < nets.length; j++) {
                const n = nets[j]
                if (n && n.connected) {
                    root.wifiSsid = n.name || ""
                    root.wifiSignal = Math.round((n.signalStrength || 0) * 100)
                    return
                }
            }
        }
    }

    Process {
        id: backlightDetect
        command: ["sh", "-c", "ls -d /sys/class/backlight/*/ 2>/dev/null | head -n1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const d = data.trim()
                if (d) root.backlightPath = d.slice(0, -1)
            }
        }
    }

    function toggleIdle() {
        if (root.idleRunning) {
            Quickshell.execDetached(["pkill", "hypridle"])
            root.idleRunning = false
        } else {
            Quickshell.execDetached(["hypridle"])
            root.idleRunning = true
        }
    }

    Process {
        id: idleCheck
        command: ["pgrep", "-x", "hypridle"]
        running: true
        onExited: (code, status) => {
            root.idleRunning = code === 0
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: idleCheck.running = true
    }

    FileView {
        id: brMaxFile
        path: root.backlightPath + "/max_brightness"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.brMax = parseInt(brMaxFile.text(), 10) || 0
    }

    FileView {
        id: brCurFile
        path: root.backlightPath + "/brightness"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.brCurrent = parseInt(brCurFile.text(), 10) || 0
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.backlightPath !== ""
        onTriggered: brCurFile.reload()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hoverCount++
        onExited: root.hoverCount--
    }

    Item {
        id: sensor
        x: 2
        y: 0
        width: 320
        height: 5
    }

    Rectangle {
        id: bodyPanel
        x: 2
        y: open ? 0 : -bodyPanel.height
        width: 320
        height: rows.height + 20
        color: "#16130f"
        border { width: 1; color: "#38332d" }

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: rows
            anchors {
                left: parent.left
                leftMargin: 10
                top: parent.top
                topMargin: 10
            }
            spacing: 6

            StatRow {
                icon: root.brightness < 0 ? "\uf1fe"
                    : root.brightness > 80 ? "\uf185"
                    : root.brightness > 40 ? "\uf159"
                    : "\uf1fe"
                label: "Brightness"
                value: root.brightness < 0 ? "…" : Math.round(root.brightness) + "%"
            }

            StatRow {
                icon: root.volumeMuted ? "\uf026" : "\uf028"
                label: "Volume"
                value: root.volumeMuted ? "Muted" : Math.round(root.volume * 100) + "%"
                valueColor: root.volumeMuted ? "#e87962" : "#cfc7ba"
            }

            StatRow {
                icon: root.batPercent < 0 ? "\uf244"
                    : root.batCharging ? "\uf0e7"
                    : root.batPercent > 80 ? "\uf240"
                    : root.batPercent > 60 ? "\uf241"
                    : root.batPercent > 40 ? "\uf242"
                    : root.batPercent > 20 ? "\uf243"
                    : "\uf244"
                label: root.batCharging ? "Battery \u00b7 Charging" : "Battery"
                value: root.batPercent < 0 ? "…" : root.batPercent + "%"
                valueColor: root.batPercent >= 0 && root.batPercent <= 20 && !root.batCharging ? "#e87962" : "#cfc7ba"
            }

            StatRow {
                icon: "\uf073"
                label: "Date"
                value: Qt.formatDateTime(root.now, "dddd, MMMM d, yyyy")
            }

            StatRow {
                icon: "\uf1eb"
                label: "Wifi"
                value: root.wifiLoaded
                    ? (root.wifiSsid ? root.wifiSsid + (root.wifiSignal ? " \u00b7 " + root.wifiSignal + "%" : "") : "Disconnected")
                    : "…"
                valueColor: root.wifiLoaded && root.wifiSsid ? "#cfc7ba" : "#8a8378"
            }

            StatRow {
                icon: "\uf293"
                label: "Bluetooth"
                value: root.btName ? root.btName : (root.btPowered ? "On" : "Off")
                valueColor: root.btName ? "#cfc7ba" : "#8a8378"
            }

            StatRow {
                icon: "\uf186"
                label: "Hypridle"
                value: root.idleRunning ? "On" : "Off"
                valueColor: root.idleRunning ? "#cfc7ba" : "#8a8378"

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverCount++
                    onExited: root.hoverCount--
                    onClicked: root.toggleIdle()
                }
            }

            Item {
                width: 300
                height: 26

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.family: "0xProto Nerd Font"
                    font.pixelSize: 12
                    color: "#8a8378"
                    text: "\uf293  Tray"
                }

                Tray {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    window: root.window
                    onEntered: root.hoverCount++
                    onExited: root.hoverCount--
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Repeater {
        model: Networking.devices

        delegate: Item {
            required property var modelData

            Connections {
                target: modelData
                function onConnectedChanged() { root.refreshWifi() }
                function onStateChanged() { root.refreshWifi() }
            }
        }
    }

    Timer {
        id: wifiProbe
        interval: 250
        repeat: true
        running: true
        property int tries: 0

        onTriggered: {
            root.refreshWifi()
            root.wifiLoaded = true
            tries++
            const populated = Networking.devices && Networking.devices.values.length > 0
            if (populated || tries >= 20) running = false
        }
    }
}