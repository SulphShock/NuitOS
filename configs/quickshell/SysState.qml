pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ─────────────────────────── UI state ───────────────────────────
    property bool qsOpen: false
    property bool actOpen: false
    property bool settingsOpen: false
    property bool remOpen: false
    property bool btOpen: false
    property bool wifiOpen: false
    property bool capOpen: false
    property bool ytOpen: false
    property bool hubOpen: false
    property bool notifOpen: false
    property bool idleDim: false
    property string username: "user"
    function closeAll() { qsOpen = actOpen = settingsOpen = remOpen = btOpen = wifiOpen = capOpen = ytOpen = hubOpen = notifOpen = false }    function toggleQs()         { const v = qsOpen;    closeAll(); qsOpen    = !v }
    function toggleHub()        { const v = hubOpen;   closeAll(); hubOpen   = !v }
    function toggleNotifs() {
        const v = notifOpen
        closeAll()
        notifOpen = !v
        if (!v) notifRead = notifications.length
    }
    function toggleActivities() { const v = actOpen;   closeAll(); actOpen   = !v }
    function toggleSettings()   { const v = settingsOpen; closeAll(); settingsOpen = !v }
    function toggleReminders()  { const v = remOpen;    closeAll(); remOpen    = !v }
    function toggleBluetooth()  { const v = btOpen;    closeAll(); btOpen    = !v }
    function toggleWifi()       { const v = wifiOpen;  closeAll(); wifiOpen  = !v }
    function toggleCaptureBoard() { const v = capOpen; closeAll(); capOpen   = !v }
    function toggleYouTubeMusic() { const v = ytOpen; closeAll(); ytOpen = !v }
    // Browser-tab finder: focuses a music.youtube.com tab in any window,
    // or opens one fresh when nothing's around.
    function ytTab() {
        runCmd([(Quickshell.env("HOME") || ("/home/" + root.username)) + "/.config/quickshell/lib/yt-tab.sh"])
    }
    function setIdle(on) { idleDim = on ? true : false; if (on) closeAll() }
    // Manual screensaver (Power dialog) → same overlay hypridle uses
    function screensaver() { setIdle(true) }

    // ─────────────────── First-run welcome (once per user) ───────────────────
    // Shown 5s after shell start when ~/.config/nuit/.welcomed is absent.
    // Dismissed only explicitly (button or Escape) so a click-away can't
    // silently skip it — and skipping never marks it seen.
    property bool welcomeOpen: false
    readonly property string welcomedFile: (Quickshell.env("HOME") || ("/home/" + root.username)) + "/.config/nuit/.welcomed"
    Process {
        id: welcomeCheck
        command: ["test", "-f", root.welcomedFile]
        onExited: code => { if (code !== 0) welcomeTimer.restart() }
        Component.onCompleted: welcomeCheck.running = true
    }
    Timer {
        id: welcomeTimer
        interval: 5000
        repeat: false
        onTriggered: root.welcomeOpen = true
    }
    function dismissWelcome() {
        runCmd(["sh", "-c", "mkdir -p ~/.config/nuit && touch ~/.config/nuit/.welcomed"])
        welcomeOpen = false
    }

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
    // Evenings out: "2h 14m left" / "38m till full". Empty when unknown.
    function fmtDur(s) {
        s = Math.round(s)
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }
    readonly property string batteryEta: {
        if (!root.battery) return ""
        if (root.charging) {
            const t = root.battery.timeToFull ?? 0
            return t > 90 ? "· " + fmtDur(t) + " till full" : ""
        }
        const t = root.battery.timeToEmpty ?? 0
        return t > 90 ? "· " + fmtDur(t) + " left" : ""
    }
    // ─────────────────────────── Notifications (native server) ─────────────────────
    property bool dnd: false
    property var notifications: []
    // Badge math: everything arrived since the panel was last opened.
    // DND only quiets the badge; the list keeps everything.
    property int notifRead: 0
    readonly property int notifUnread: dnd ? 0 : Math.max(0, notifications.length - notifRead)
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
    Component.onCompleted: { refreshNetwork(); refreshBt(); blProbe.running = true; ppGet.running = true; whoami.running = true; remMkdir.running = true }

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

    // ─────── Network extras: portal, IPs, talkers, neighbors ───────
    property string localIp: ""
    property string publicIp: ""
    property bool portalSuspected: false
    property var procRows: []
    property var nearbyHosts: []
    property bool nearbyScanning: false
    property var procPrev: ({})
    property double procPrevAt: 0

    function refreshNetExtras() {
        ipProc.running = true
        pubProc.running = true
        portalProc.running = true
    }
    Process {
        id: ipProc
        command: ["sh", "-c", "ip -o -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}'"]
        stdout: StdioCollector {
            onStreamFinished: root.localIp = text.trim()
        }
    }
    Process {
        id: pubProc
        command: ["curl", "-s", "--max-time", "5", "https://api.ipify.org"]
        stdout: StdioCollector { onStreamFinished: root.publicIp = text.trim() }
    }
    // Same check Android uses: anything but 204 while connected = login wall.
    Process {
        id: portalProc
        command: ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "3", "http://connectivitycheck.gstatic.com/generate_204"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.trim()
                root.portalSuspected = !(c === "" || c === "000" || c === "204")
            }
        }
    }
    function openPortal() { runCmd(["xdg-open", "http://connectivitycheck.gstatic.com/generate_204"]) }
    Timer {
        interval: 30000; repeat: true
        running: root.wifiOpen && (root.wifiSsid !== "" || root.wired)
        triggeredOnStart: true
        onTriggered: portalProc.running = true
    }
    // Per-process traffic from ss: pair each socket with its process and
    // byte counters, diff cumulatives for rates. TCP only, top 5 talkers.
    Process {
        id: ssProc
        command: ["ss", "-tip"]
        stdout: StdioCollector { onStreamFinished: root.ingestSs(text) }
    }
    function ingestSs(text) {
        const totals = {}
        let cur = null
        for (const line of text.split("\n")) {
            if (line === "" || /^\s*State/.test(line)) continue
            if (!/^\s/.test(line)) { cur = null; continue }
            let m = line.match(/users:\(\("([^"]+)",pid=(\d+)/)
            if (m) { cur = m[1]; if (!totals[cur]) totals[cur] = { rx: 0, tx: 0 }; continue }
            if (cur) {
                m = line.match(/bytes_acked:(\d+)/)
                if (m) totals[cur].tx += parseInt(m[1])
                m = line.match(/bytes_received:(\d+)/)
                if (m) totals[cur].rx += parseInt(m[1])
            }
        }
        const now = Date.now() / 1000
        const rows = []
        if (root.procPrevAt > 0) {
            const dt = Math.max(1, now - root.procPrevAt)
            for (const k in totals) {
                const p = root.procPrev[k] || { rx: 0, tx: 0 }
                const rx = Math.max(0, (totals[k].rx - p.rx) / dt)
                const tx = Math.max(0, (totals[k].tx - p.tx) / dt)
                if (rx + tx > 0) rows.push({ proc: k, rxRate: rx, txRate: tx })
            }
            rows.sort((a, b) => (b.rxRate + b.txRate) - (a.rxRate + a.txRate))
        }
        root.procPrev = totals
        root.procPrevAt = now
        root.procRows = rows.slice(0, 5)
    }
    function fmtRate(b) {
        if (b < 1024) return Math.round(b) + " B/s"
        if (b < 1048576) return (b / 1024).toFixed(1) + " KB/s"
        return (b / 1048576).toFixed(2) + " MB/s"
    }
    Timer {
        interval: 3000; repeat: true
        running: root.wifiOpen
        triggeredOnStart: true
        onTriggered: ssProc.running = true
    }
    // Neighbors: whoever ARP knows about, plus hostnames where they exist.
    function refreshNearby() {
        root.nearbyScanning = true
        neighProc.running = true
    }
    Process {
        id: neighProc
        command: ["ip", "neigh", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = []
                for (const line of text.trim().split("\n")) {
                    const m = line.match(/^(\S+)\s+dev\s+(\S+)\s+lladdr\s+([0-9a-fA-F:]+)\s+(\S+)/)
                    if (!m || m[1].indexOf(":") >= 0) continue
                    if (m[4] === "FAILED" || m[4] === "INCOMPLETE") continue
                    rows.push({ ip: m[1], host: "", mac: m[3] })
                }
                root.nearbyHosts = rows
                if (rows.length > 0) {
                    hostProc.command = ["getent", "hosts"].concat(rows.map(r => r.ip))
                    hostProc.running = true
                } else root.nearbyScanning = false
            }
        }
    }
    Process {
        id: hostProc
        stdout: StdioCollector {
            onStreamFinished: {
                const names = {}
                for (const line of text.trim().split("\n")) {
                    const p = line.trim().split(/\s+/)
                    if (p.length >= 2) names[p[0]] = p[1]
                }
                root.nearbyHosts = root.nearbyHosts.map(r => ({ ip: r.ip, host: names[r.ip] || "", mac: r.mac }))
                root.nearbyScanning = false
            }
        }
        onExited: root.nearbyScanning = false
    }

    // ─────────────────────────── Bluetooth (bluetoothctl) ───────────────────────────
    property bool btPowered: false
    property var btDevices: []            // every known device {address, name}
    property var btConnected: []          // known + connected
    property var btPaired: []             // paired but not connected
    property var btAvailable: []          // discovered, never paired
    property var btConnectedAddresses: []
    property var btPairedAddresses: []
    property string btError: ""
    property bool bluetoothScanning: false
    property string btPendingPair: ""
    function refreshBt() { btShow.running = true }
    function refreshBtLists() { btScan.running = true; btConnectedScan.running = true; btPairedScan.running = true }
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
    function scanBluetooth() {
        btError = ""
        bluetoothScanning = true
        btDiscover.running = true   // timed discovery, then the three list scans
    }
    function rebuildBt() {
        // Split every known device by its address membership. Names come
        // from the full device list; paired/connected scans give addresses.
        const connected = [], paired = [], available = []
        for (const d of btDevices) {
            if (btConnectedAddresses.indexOf(d.address) >= 0)
                connected.push({ address: d.address, name: d.name, action: "disconnect" })
            else if (btPairedAddresses.indexOf(d.address) >= 0)
                paired.push({ address: d.address, name: d.name, action: "connect" })
            else
                available.push({ address: d.address, name: d.name, action: "pair" })
        }
        root.btConnected = connected
        root.btPaired = paired
        root.btAvailable = available
        root.refreshBtBatteries()
    }
    // Per-device battery, for hardware that reports it. BlueZ prints it in
    // `bluetoothctl info`; queried on panel open, not polled.
    property var btBatteries: ({})
    function refreshBtBatteries() {
        if (btBattProc.running) return
        const addrs = btConnected.map(d => d.address)
        if (addrs.length === 0) { btBatteries = {}; return }
        btBattProc.command = ["sh", "-c", 'for a in ' + addrs.join(" ") + '; do p=$(bluetoothctl info "$a" 2>/dev/null | grep "Battery Percentage" | grep -o "([0-9]*%)" | tr -d "()%"); echo "$a ${p:-}"; done']
        btBattProc.running = true
    }
    Process {
        id: btBattProc
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const line of text.trim().split("\n")) {
                    const p = line.split(" ")
                    if (p.length === 2 && p[1] !== "") m[p[0]] = p[1]
                }
                root.btBatteries = m
            }
        }
    }
    function btAction(address, action) {
        btError = ""
        if (action === "disconnect") {
            btDisconnect.command = ["bluetoothctl", "disconnect", address]
            btDisconnect.running = true
        } else if (action === "pair") {
            btPendingPair = address
            btPair.command = ["bluetoothctl", "pair", address]
            btPair.running = true
        } else {
            connectBluetooth(address)
        }
    }
    function connectBluetooth(address) {
        btError = ""
        btConnect.command = ["bluetoothctl", "connect", address]
        btConnect.running = true
    }
    function parseBtDevices(text) {
        const found = []
        for (const line of text.trim().split("\n")) {
            const parts = line.trim().split(" ")
            if (parts.length >= 3 && parts[0] === "Device")
                found.push({ address: parts[1], name: parts.slice(2).join(" ") })
        }
        return found
    }
    function parseBtAddresses(text) {
        const addresses = []
        for (const line of text.trim().split("\n")) {
            const parts = line.trim().split(" ")
            if (parts.length >= 2 && parts[0] === "Device") addresses.push(parts[1])
        }
        return addresses
    }
    Process {
        id: btDiscover
        command: ["bluetoothctl", "--timeout", "8", "scan", "on"]
        onExited: root.refreshBtLists()
    }
    Process {
        id: btScan
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: { root.btDevices = parseBtDevices(text); root.rebuildBt() }
        }
        onExited: exitCode => { root.bluetoothScanning = false; if (exitCode !== 0) root.btError = "Unable to scan Bluetooth devices" }
    }
    Process {
        id: btConnectedScan
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: { root.btConnectedAddresses = parseBtAddresses(text); root.rebuildBt() }
        }
    }
    Process {
        id: btPairedScan
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: StdioCollector {
            onStreamFinished: { root.btPairedAddresses = parseBtAddresses(text); root.rebuildBt() }
        }
    }
    Process {
        id: btConnect
        onExited: exitCode => {
            if (exitCode !== 0) root.btError = "Could not connect to that device"
            root.refreshBtLists()
        }
    }
    Process {
        id: btDisconnect
        onExited: exitCode => {
            if (exitCode !== 0) root.btError = "Could not disconnect that device"
            root.refreshBtLists()
        }
    }
    Process {
        id: btPair
        onExited: exitCode => {
            if (exitCode !== 0) { root.btError = "Pairing failed — keep the device discoverable"; root.btPendingPair = "" }
            else {
                btTrust.command = ["bluetoothctl", "trust", root.btPendingPair]
                btTrust.running = true
            }
        }
    }
    Process {
        id: btTrust
        onExited: exitCode => {
            const addr = root.btPendingPair
            root.btPendingPair = ""
            if (exitCode !== 0) root.btError = "Paired, but trust failed"
            else if (addr) connectBluetooth(addr)
            root.refreshBtLists()
        }
    }

    // ─────────── Pinned auto-reconnect (the one the stock widget lacks) ───────────
    // Starred devices get retried every 20s (60s cooldown each) whether any
    // panel is open or not — covers out-of-range radios and post-sleep drops.
    // Pins live at ~/.local/share/nuit/bt-pins.json as ["AA:BB:…"].
    property var btPins: []
    property var btCooldown: ({})
    readonly property string btPinsFile: (Quickshell.env("HOME") || ("/home/" + root.username)) + "/.local/share/nuit/bt-pins.json"
    function isPinned(addr) { return btPins.indexOf(addr) >= 0 }
    function togglePin(addr) {
        btPins = isPinned(addr) ? btPins.filter(a => a !== addr) : btPins.concat([addr])
        saveBtPins()
    }
    function saveBtPins() {
        pinsWrite.path = root.btPinsFile
        pinsWrite.setText(JSON.stringify(btPins))
    }
    FileView {
        id: pinsWrite
        atomicWrites: true
    }
    FileView {
        id: pinsLoad
        path: root.btPinsFile
        watchChanges: true
        onLoaded: {
            try {
                const arr = JSON.parse(text)
                if (Array.isArray(arr)) root.btPins = arr.filter(a => typeof a === "string")
            } catch (e) { root.btPins = [] }
        }
    }
    Process { id: btPinConnect }
    Timer {
        interval: 20000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            if (btPinConnect.running || btPins.length === 0) return
            const now = Date.now()
            const live = {}
            for (const d of btConnected) live[d.address] = true
            for (const addr of btPins) {
                if (live[addr]) continue
                if (now - (btCooldown[addr] || 0) < 60000) continue
                btCooldown[addr] = now
                btPinConnect.command = ["bluetoothctl", "connect", addr]
                btPinConnect.running = true
                break   // one in flight at a time
            }
        }
    }

    // ─────────────────────────── Brightness (via brightnessctl/logind) ─────────────
    property real brightness: 0.7
    property int blMax: 1
    property string blDevice: ""
    // False on VMs / desktops without a backlight: TopBar hides the tile.
    readonly property bool hasBacklight: blDevice !== ""
    Process {
        id: blProbe
        command: ["brightnessctl", "-m"]   // name,class,cur,pct,max
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0].split(",")
                root.blDevice = f[0]
                root.blMax = parseInt(f[4]) || 1
                root.brightness = Math.min(1, (parseInt(f[2]) || 1) / root.blMax)
                blRead.path = "/sys/class/backlight/" + root.blDevice + "/brightness"
            }
        }
    }
    FileView {   // follow external changes (keyboard keys, etc.) — read-only, world-readable
        id: blRead
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text)
            if (!isNaN(v) && root.blMax > 0) root.brightness = Math.min(1, Math.max(0.03, v / root.blMax))
        }
    }
    // NOTE: never write sysfs directly (FileView → EACCES as non-root).
    // brightnessctl goes through logind D-Bus SetBrightness, so it works unprivileged.
    Process {
        id: blSet
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.warn("brightnessctl:", text.trim()) }
        onExited: code => { if (code !== 0) console.warn("brightnessctl exited with code", code) }
    }
    function setBrightness(v) { brightness = Math.min(1, Math.max(0.03, v)); blCommit.restart() }
    Timer {
        id: blCommit; interval: 40
        onTriggered: {
            if (!root.blDevice) return
            blSet.command = ["brightnessctl", "-d", root.blDevice, "-q", "s",
                String(Math.max(1, Math.round(root.brightness * root.blMax)))]
            blSet.running = true
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

    // ─────────────────────────── Night Light (hyprshade) ────────────────────────────
    // gammastep can't work here: Hyprland has no gamma-control protocol.
    // hyprshade applies our gentle 4500K screen shader instead (stock
    // blue-light-filter at 2600K is too strong). Tune it in
    // ~/.config/hypr/shaders/nuit-night-light.glsl.
    property bool nightLight: false
    Process { id: nlProc }
    function setNightLight(on) {
        nightLight = on
        nlProc.command = on ? ["hyprshade", "on", "nuit-night-light"] : ["hyprshade", "off"]
        nlProc.running = true
    }

    // ─────────────────────── OS update center ───────────────────────
    // Counts pending pacman+AUR updates (yay checks unprivileged) and
    // launches the full refresh — clock, pacman, AUR, flatpak — in a
    // terminal so sudo + confirmations stay visible.
    property int pendingUpdates: -1   // -1 = haven't checked yet
    property double lastUpdateCheck: 0
    readonly property string updateSubtitle: pendingUpdates < 0 ? "Checking…"
        : pendingUpdates === 0 ? "Up to date" : pendingUpdates + " waiting"
    Process {
        id: updCheck
        command: ["sh", "-c", "yay -Qu 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim())
                root.pendingUpdates = isNaN(n) ? 0 : n
                root.lastUpdateCheck = Date.now()
            }
        }
        onExited: code => { if (code !== 0) { root.pendingUpdates = 0; root.lastUpdateCheck = Date.now() } }
    }
    function checkUpdates() { updCheck.running = true }
    // Gentle throttle: UI entry points re-check at most every 30 min.
    function maybeRefreshUpdates() {
        if (Date.now() - lastUpdateCheck > 30 * 60000) checkUpdates()
    }
    function runOsUpdate() {
        const script = (Quickshell.env("HOME") || ("/home/" + root.username)) + "/.config/quickshell/lib/os-update.sh"
        runCmd(["ghostty", "-e", script])
    }
    Timer {
        interval: 6 * 3600000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.checkUpdates()
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

    // ─────────────────────────── Reminders ──────────────────────────────
    // persisted at ~/.local/share/nuit/reminders.json as [{id, text, when}]
    property var reminders: []
    property int remSeq: 0
    readonly property string remFile: (Quickshell.env("HOME") || ("/home/" + root.username)) + "/.local/share/nuit/reminders.json"

    // "15m", "2h", "1h30m" from now, or "HH:MM" today (tomorrow if passed)
    function parseReminderWhen(s) {
        s = (s || "").trim().toLowerCase()
        let m = s.match(/^(\d+)\s*m(in)?$/)
        if (m) return Date.now() + parseInt(m[1]) * 60000
        m = s.match(/^(\d+)\s*h(ours?)?$/)
        if (m) return Date.now() + parseInt(m[1]) * 3600000
        m = s.match(/^(\d+)\s*h\s*(\d+)\s*m?$/)
        if (m) return Date.now() + (parseInt(m[1]) * 60 + parseInt(m[2])) * 60000
        m = s.match(/^(\d{1,2}):(\d{2})$/)
        if (m) {
            const d = new Date()
            d.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0)
            if (d.getTime() <= Date.now()) d.setDate(d.getDate() + 1)
            return d.getTime()
        }
        return 0
    }
    function reminderLabel(when) {
        const ms = when - Date.now()
        if (ms <= 0) return "due"
        const min = Math.floor(ms / 60000)
        if (min < 60) return "in " + min + "m"
        const h = Math.floor(min / 60)
        if (h < 24) return "in " + h + "h" + (min % 60 ? " " + (min % 60) + "m" : "")
        return Qt.formatDateTime(new Date(when), "ddd h:mm AP")
    }
    function addReminder(text, whenStr) {
        const t = (text || "").trim()
        const when = parseReminderWhen(whenStr)
        if (!t || !when) return false
        remSeq += 1
        reminders = reminders.concat([{ id: remSeq, text: t, when: when }])
            .sort((a, b) => a.when - b.when)
        saveReminders()
        return true
    }
    function delReminder(id) {
        reminders = reminders.filter(r => r.id !== id)
        saveReminders()
    }
    function refreshReminders() {
        remLoad.reload()
    }
    function saveReminders() {
        remWrite.path = root.remFile
        remWrite.setText(JSON.stringify(reminders))
    }
    function fireDueReminders() {
        const now = Date.now()
        const due = reminders.filter(r => r.when <= now)
        if (due.length === 0) return
        reminders = reminders.filter(r => r.when > now)
        saveReminders()
        for (const r of due) {
            remNotify.command = ["notify-send", "-a", "Nuit", "-u", "critical", "Reminder", r.text]
            remNotify.running = true
        }
    }
    Process { id: remNotify }
    Process {
        id: remMkdir
        command: ["sh", "-c", "mkdir -p \"$HOME/.local/share/nuit\""]
        onExited: remLoad.reload()
    }
    FileView {
        id: remLoad
        path: root.remFile
        watchChanges: true
        onLoaded: {
            try {
                const arr = JSON.parse(text)
                if (Array.isArray(arr)) {
                    root.reminders = arr.filter(r => r && r.when > Date.now() - 60000)
                        .sort((a, b) => a.when - b.when)
                    for (const r of root.reminders)
                        if (r.id > root.remSeq) root.remSeq = r.id
                }
            } catch (e) { root.reminders = [] }
        }
    }
    FileView {
        id: remWrite
        atomicWrites: true
    }
    Timer {
        id: remTimer
        interval: 15000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.fireDueReminders()
    }
}