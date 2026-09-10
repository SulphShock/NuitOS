import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

PanelWindow {
    id: bar
    property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.panelBg                       // #282828 @ 95%
    WlrLayershell.namespace: "quickshell:gnome-bar"

    // ── bar-wide mouse: scroll anywhere on the bar to switch workspace ──
    // (chips with their own wheel actions, e.g. volume, sit above and keep priority)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            bar.cycleWorkspace(wheel.angleDelta.y > 0 ? 1 : -1)
            wheel.accepted = true
        }
    }

    // ── status icon resolution ──
    readonly property string volIcon:
        SysState.muted || SysState.volume <= 0.01 ? "audio-volume-muted-symbolic"
      : SysState.volume < 0.33 ? "audio-volume-low-symbolic"
      : SysState.volume < 0.66 ? "audio-volume-medium-symbolic"
      : "audio-volume-high-symbolic"

    readonly property string netIcon: {
        if (SysState.wifiSsid !== "") {
            const s = SysState.wifiStrength
            return s > 75 ? "network-wireless-signal-excellent-symbolic"
                 : s > 50 ? "network-wireless-signal-good-symbolic"
                 : s > 25 ? "network-wireless-signal-ok-symbolic"
                 : "network-wireless-signal-weak-symbolic"
        }
        if (SysState.wired) return "network-wired-symbolic"
        return SysState.wifiEnabled ? "network-wireless-symbolic"
                                    : "network-wireless-disconnected-symbolic"
    }

    readonly property string netLabel: SysState.wired ? "LAN"
        : SysState.wifiSsid !== "" ? "Wi-Fi" : "Off"
    readonly property string volumeLabel: SysState.muted
        ? "Mute" : Math.round(SysState.volume * 100) + "%"
    readonly property string batteryLabel: Math.max(0, Math.min(100, SysState.batteryPct))
        + "%" + (SysState.charging ? "+" : "")
    readonly property string battIcon: {
        const p = Math.max(0, Math.min(100, SysState.batteryPct))
        // Adwaita ships battery-level-{20..100} (+charging); low charge
        // gets the dedicated caution glyph instead of a missing level.
        if (p <= 10) return "battery-caution-symbolic"
        const lvl = Math.min(100, Math.max(20, Math.round(p / 10) * 10))
        return "battery-level-" + lvl
            + (SysState.charging ? "-charging" : "") + "-symbolic"
    }
    property int workspaceRevision: 0
    // GNOME-style dynamic strip: always 1..5, extends to the highest live
    // workspace, capped at 10 to match the Super+1..0 binds. No dead buttons.
    readonly property var workspaceIds: {
        workspaceRevision
        let top = 5
        for (const workspace of (Hyprland.workspaces?.values ?? [])) {
            if (workspace.id > top) top = workspace.id
        }
        top = Math.min(10, top)
        const ids = []
        for (let i = 1; i <= top; i++) ids.push(i)
        return ids
    }
    Connections {
        target: Hyprland
        function onRawEvent() { bar.workspaceRevision++ }
    }
    Process { id: workspaceSwitch }

    function switchWorkspace(target) {
        workspaceSwitch.command = ["hyprctl", "dispatch",
            "workspace", String(target)]
        workspaceSwitch.running = true
    }

    function cycleWorkspace(direction) {
        const target = direction > 0 ? "e+1" : "e-1"
        workspaceSwitch.command = ["hyprctl", "dispatch",
            "workspace", target]
        workspaceSwitch.running = true
    }

    // Fade + scale burp whenever a status icon needs attention
    function pulseIcon(item) {
        pulseAnim.target = item
        pulseAnim.restart()
    }

    SequentialAnimation {
        id: pulseAnim
        property Item target
        NumberAnimation {
            target: pulseAnim.target
            property: "opacity"
            to: 0.2
            duration: 90
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: pulseAnim.target
            property: "opacity"
            to: 1
            duration: 160
            easing.type: Easing.OutBack
        }
    }

    // One status icon chip inside the right-hand pill (network / volume / battery)
    component StatusIcon: Rectangle {
        id: chip
        property string source: ""
        property color tint: Theme.foreground
        signal clicked()
        signal wheelAdjusted(int direction)
        width: 18; height: 18; radius: 9
        color: mouse.containsMouse
            ? (statusPill.color === Theme.accent ? Theme.hoverStrong : Theme.hover)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        WhiteIcon {
            id: glyph
            anchors.centerIn: parent
            size: 12
            source: chip.source
            tint: chip.tint
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
            onWheel: function(wheel) {
                chip.wheelAdjusted(wheel.angleDelta.y > 0 ? 1 : -1)
                wheel.accepted = true
            }
        }
        function pulse() { bar.pulseIcon(glyph) }
    }

    // ── LEFT: logo launcher + workspaces ──
    Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 8 }
        spacing: 8

        Rectangle {
            width: 20
            height: 20
            radius: Theme.radiusSm
            color: logoMouse.containsMouse || SysState.actOpen ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: Qt.resolvedUrl("../assets/Logo.png")
                fillMode: Image.PreserveAspectFit
            }
            MouseArea {
                id: logoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SysState.toggleActivities()
            }
        }

        Item {
            id: workspaceArea
            width: workspaceStrip.implicitWidth
            height: 20
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function(wheel) {
                    bar.cycleWorkspace(wheel.angleDelta.y > 0 ? 1 : -1)
                    wheel.accepted = true
                }
            }
        Row {
            id: workspaceStrip
            anchors.fill: parent
            spacing: 2
            Repeater {
                model: bar.workspaceIds
                delegate: Rectangle {
                    required property int modelData
                    id: workspaceButton
                    readonly property var workspace: Hyprland.workspaces?.values.find(w => w.id === modelData) ?? null
                    readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
                    width: 18
                    height: 18
                    radius: 9
                    color: Hyprland.focusedWorkspace?.id === modelData ? Theme.accent
                        : workspaceMouse.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Hyprland.focusedWorkspace?.id === modelData ? Theme.accentText : Theme.dimText
                        font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                    }
                    Rectangle {
                        visible: workspaceButton.occupied
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: 8
                        height: 2
                        radius: 1
                        color: Hyprland.focusedWorkspace?.id === modelData ? Theme.accentText : Theme.foreground
                    }
                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bar.switchWorkspace(modelData)
                        }
                        onWheel: function(wheel) {
                            bar.cycleWorkspace(wheel.angleDelta.y > 0 ? 1 : -1)
                            wheel.accepted = true
                        }
                    }
                }
            }
        }
        }

        // GNOME app-name pattern: focused window title, fixed slot so the
        // bar geometry never jumps; collapses when the desktop is empty.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: appTitle.text === "" ? 0 : 220
            visible: appTitle.text !== ""
            clip: true
            Text {
                id: appTitle
                width: 220
                text: Hyprland.activeToplevel?.title ?? ""
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 11 }
            }
        }
    }

    // ── CENTER: clock + date (GNOME parity) ──
    PillButton {
        id: clockPill
        property string timeText: {
            SysState.clock.seconds          // per-second refresh dependency
            const d = new Date()
            return Qt.formatDate(d, "ddd MMM d  ") + Qt.formatTime(d, "h:mm AP")
        }
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        label: timeText
        active: SysState.calOpen
        onClicked: SysState.toggleCalendar()
    }

    // ── RIGHT: unified GNOME status button ──
    Rectangle {
        id: statusPill
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
        width: statusRow.implicitWidth + 16
        height: 20
        radius: height / 2
        color: statusMouse.pressed || SysState.qsOpen ? Theme.accent
             : statusMouse.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SysState.toggleQs()
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 2

            // Network — click to open Quick Settings.
            // Dim when offline entirely (no SSID and no wire) so the
            // radio-on-but-disconnected state reads differently from Off.
            StatusIcon {
                id: netBtn
                source: Theme.icon(bar.netIcon)
                tint: (SysState.wifiSsid === "" && !SysState.wired)
                    ? Theme.dimText
                    : (statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground)
                onClicked: SysState.toggleQs()
                Connections {
                    target: SysState
                    function onWifiSsidChanged() { netBtn.pulse() }
                    function onWifiEnabledChanged() { netBtn.pulse() }
                    function onWiredChanged() { netBtn.pulse() }
                }
            }

            // Volume — click to mute/unmute, scroll to change level
            StatusIcon {
                id: volBtn
                source: Theme.icon(bar.volIcon)
                tint: statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground
                onClicked: SysState.toggleMute()
                onWheelAdjusted: direction => SysState.setVolume(SysState.volume + direction * 0.05)
                Connections {
                    target: SysState
                    function onMutedChanged() { volBtn.pulse() }
                }
            }

            // Battery — click opens Quick Settings
            StatusIcon {
                id: battBtn
                source: Theme.icon(bar.battIcon)
                tint: statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground
                onClicked: SysState.toggleQs()
                Connections {
                    target: SysState
                    function onChargingChanged() { battBtn.pulse() }
                }
            }

            // Brightness — scroll to adjust, click opens Quick Settings slider.
            // Hidden where no backlight device exists (VMs, some desktops).
            StatusIcon {
                id: briBtn
                visible: SysState.hasBacklight
                source: Theme.icon("display-brightness-symbolic")
                tint: statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground
                onClicked: SysState.toggleQs()
                onWheelAdjusted: direction => SysState.setBrightness(SysState.brightness + direction * 0.05)
                Connections {
                    target: SysState
                    function onBrightnessChanged() { briBtn.pulse() }
                }
            }

            // Reminders — click opens the reminders panel
            StatusIcon {
                id: remBtn
                source: Theme.icon("alarm-symbolic")
                tint: SysState.reminders.length > 0
                    ? (statusPill.color === Theme.accent ? Theme.accentText : Theme.accent)
                    : (statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground)
                onClicked: SysState.toggleReminders()
                Connections {
                    target: SysState
                    function onRemindersChanged() { remBtn.pulse() }
                }
            }
        }
    }
}