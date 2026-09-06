pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ─────────────────────────── UI state ───────────────────────────
    property bool qsOpen: false
    property bool calOpen: false
    property bool actOpen: false
    property bool settingsOpen: false
    property string username: "user"
    function closeAll() { qsOpen = calOpen = actOpen = settingsOpen = false }
    function toggleQs()         { const v = qsOpen;    closeAll(); qsOpen    = !v }
    function toggleCalendar()   { const v = calOpen;   closeAll(); calOpen   = !v }
    function toggleActivities() { const v = actOpen;   closeAll(); actOpen   = !v }
    function toggleSettings()   { const v = settingsOpen; closeAll(); settingsOpen = !v }

    readonly property SystemClock clock: SystemClock { precision: SystemClock.Seconds }

    // ─────────────────────────── Audio (PipeWire, native) ───────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false
    function setVolume(v)  { if (sink?.audio) sink.audio.volume = Math.min(1, Math.max(0, v)) }
    function toggleMute()  { if (sink?.audio) sink.audio.muted = !sink.audio.muted }

    // ─────────────────────────── Battery (UPower, native) ───────────────────────────
    // Note: quickshell normalizes percentage to 0..1
    readonly property var  battery: UPower.displayDevice
    readonly property int  batteryPct: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging

    // ─────────────────────────── Media (MPRIS, native) ───────────────────────────
    readonly property var player:
        Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing)
        ?? Mpris.players.values[0] ?? null

    // ─────────────────────────── Notifications (native server) ─────────────────────
    property bool dnd: false
    property var notifications: []
    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        onNotification: notif => {
            notif.tracked = true                              // keep it alive for the center
            root.notifications = [notif].concat(root.notifications).slice(0, 50)
        }
    }
    function dismissNotification(n) {
        root.notifications = root.notifications.filter(x => x !== n)
        n.dismiss()
    }
    function clearNotifications() {
        for (const n of root.notifications) n.dismiss()
        root.notifications = []
    }

    // ─────────────────────────── NetworkManager (nmcli) ─────────────────────────────
    property bool wifiEnabled: false
    property bool wired: false
    property string wifiSsid: ""
    property int wifiStrength: 0
    property var wifiNetworks: []
    property string wifiError: ""
    property bool wifiScanning: false

    function refreshNetwork() { nmWifi.running = true; nmDev.running = true }
    function scanWifi() { wifiError = ""; wifiScanning = true; nmScan.running = true }
    function connectWifi(ssid, password) {
        wifiError = ""
        nmConnect.command = password === ""
            ? ["nmcli", "device", "wifi", "connect", ssid]
            : ["nmcli", "device", "wifi", "connect", ssid, "password", password]
        nmConnect.running = true
    }
    Component.onCompleted: { refreshNetwork(); refreshBt(); blProbe.running = true; ppGet.running = true; whoami.running = true }

    Process {
        id: whoami
        command: ["whoami"]
        stdout: StdioCollector { onStreamFinished: root.username = text.trim() || "user" }
    }

    Process {
        id: nmWifi
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    Process {
        id: nmDev
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wired = false; root.wifiSsid = ""
                for (const l of text.trim().split("\n")) {
                    const p = l.split(":")
                    if (p.length >= 3) {
                        if (p[0] === "wifi" && p[1] === "connected")
                            root.wifiSsid = p.slice(2).join(":")
                        if (p[0] === "ethernet" && p[1] === "connected")
                            root.wired = true
                    }
                }
            }
        }
    }
    // Event stream: re-query whenever NetworkManager state changes
    Process {
        id: nmMonitor
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: root.refreshNetwork() }
    }
    Timer {   // periodic signal-strength sampling
        interval: 5000; running: root.wifiEnabled; repeat: true; triggeredOnStart: true
        onTriggered: nmSignal.running = true
    }
    Process {
        id: nmSignal
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of text.trim().split("\n")) {
                    const p = l.split(":")
                    if (p.length >= 2 && (p[0] === "*" || p[0] === "yes")) {
                        root.wifiStrength = parseInt(p[1]) || 0
                        break
                    }
                }
            }
        }
    }
    Process { id: nmWifiSet; onExited: root.refreshNetwork() }
    function setWifi(on) {
        nmWifiSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        nmWifiSet.running = true
    }
    Process {
        id: nmScan
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = []
                for (const line of text.trim().split("\n")) {
                    const parts = line.split(":")
                    if (parts.length < 4 || parts[1] === "") continue
                    const ssid = parts[1]
                    if (!found.some(n => n.ssid === ssid))
                        found.push({ connected: parts[0] === "*", ssid: ssid,
                            strength: parseInt(parts[2]) || 0, secured: parts.slice(3).join(":") !== "" })
                }
                root.wifiNetworks = found
            }
        }
        onExited: exitCode => { root.wifiScanning = false; if (exitCode !== 0) root.wifiError = "Unable to scan Wi-Fi networks" }
    }
    Process {
        id: nmConnect
        onExited: exitCode => {
            if (exitCode !== 0) root.wifiError = "Could not connect to that network"
            else root.refreshNetwork()
        }
    }

    // ─────────────────────────── Bluetooth (bluetoothctl) ───────────────────────────
    property bool btPowered: false
    property var btDevices: []
    property var btConnectedAddresses: []
    property string btError: ""
    property bool bluetoothScanning: false
    function refreshBt() { btShow.running = true }
    Process {
        id: btShow
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector { onStreamFinished: root.btPowered = /Powered: yes/.test(text) }
    }
    Process { id: btSet; onExited: root.refreshBt() }
    function setBluetooth(on) {
        btSet.command = ["bluetoothctl", "power", on ? "on" : "off"]
        btSet.running = true
    }
    function scanBluetooth() { btError = ""; bluetoothScanning = true; btScan.running = true; btConnectedScan.running = true }
    function connectBluetooth(address) {
        btError = ""
        btConnect.command = ["bluetoothctl", "connect", address]
        btConnect.running = true
    }
    Process {
        id: btScan
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = []
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(" ")
                    if (parts.length >= 3 && parts[0] === "Device")
                        found.push({ address: parts[1], name: parts.slice(2).join(" ") })
                }
                root.btDevices = found
            }
        }
        onExited: exitCode => { root.bluetoothScanning = false; if (exitCode !== 0) root.btError = "Unable to scan Bluetooth devices" }
    }
    Process {
        id: btConnectedScan
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const addresses = []
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(" ")
                    if (parts.length >= 2 && parts[0] === "Device") addresses.push(parts[1])
                }
                root.btConnectedAddresses = addresses
            }
        }
    }
    Process {
        id: btConnect
        onExited: exitCode => {
            if (exitCode !== 0) root.btError = "Could not connect to that device"
            else root.refreshBt()
        }
    }

    // ─────────────────────────── Brightness (backlight sysfs) ───────────────────────
    property real brightness: 0.7
    property int blMax: 1
    property string blDevice: ""
    Process {
        id: blProbe
        command: ["brightnessctl", "-m"]   // name,class,cur,max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0].split(",")
                root.blDevice = f[0]
                root.blMax = parseInt(f[3]) || 1
                root.brightness = Math.min(1, (parseInt(f[2]) || 1) / root.blMax)
                blRead.path = "/sys/class/backlight/" + root.blDevice + "/brightness"
            }
        }
    }
    FileView {   // follow external changes (keyboard keys, etc.)
        id: blRead
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text)
            if (!isNaN(v) && root.blMax > 0) root.brightness = Math.min(1, Math.max(0.03, v / root.blMax))
        }
    }
    FileView { id: blWrite; atomicWrites: true }
    function setBrightness(v) { brightness = Math.min(1, Math.max(0.03, v)); blCommit.restart() }
    Timer {
        id: blCommit; interval: 40
        onTriggered: {
            if (!root.blDevice) return
            blWrite.path = "/sys/class/backlight/" + root.blDevice + "/brightness"
            blWrite.setText(String(Math.max(1, Math.round(root.brightness * root.blMax))))
            blWrite.waitForJob()
        }
    }

    // ─────────────────────── Power Profiles (power-profiles-daemon) ─────────────────
    property string powerProfile: "balanced"
    Process {
        id: ppGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.powerProfile = text.trim() }
    }
    Process { id: ppSet; onExited: ppGet.running = true }
    function setPowerProfile(p) {
        ppSet.command = ["powerprofilesctl", "set", p]
        ppSet.running = true
    }

    // ─────────────────────────── Night Light (gammastep) ────────────────────────────
    property bool nightLight: false
    Process { id: nlStart; command: ["gammastep", "-O", "4500K"] }
    Process { id: nlStop;  command: ["pkill", "gammastep"] }
    function setNightLight(on) {
        nightLight = on
        on ? (nlStart.running = true) : (nlStop.running = true)
    }

    // ──────────────────────── logind actions + app launcher ─────────────────────────
    Process { id: sysProc }
    function runCmd(cmd) { sysProc.command = cmd; sysProc.running = true }
    function powerOff() { runCmd(["systemctl", "poweroff"]) }
    function reboot()   { runCmd(["systemctl", "reboot"]) }
    function suspend()  { runCmd(["systemctl", "suspend"]) }
    function hibernate() { runCmd(["systemctl", "hibernate"]) }
    function lock()     { runCmd(["loginctl", "lock-session"]) }
    function logout()   { runCmd(["loginctl", "terminate-user", root.username]) }

    Process { id: launcher }
    function launch(execLine) {
        const cmd = execLine.replace(/%[a-zA-Z]/g, "").trim()   // strip desktop-entry field codes
        launcher.command = ["sh", "-c", cmd + " >/dev/null 2>&1 &"]
        launcher.running = true
        closeAll()
    }
}