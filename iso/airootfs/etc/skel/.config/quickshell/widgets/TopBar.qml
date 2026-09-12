import QtQuick
import Quickshell
import Quickshell.Hyprland
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
    // NOTE (Hyprland 0.55+ Lua): plain `hyprctl dispatch workspace N` no
    // longer works — dispatch is shorthand for eval 'hl.dispatch(...)'.
    // Send Lua directly over the native Hyprland socket instead of hyprctl.
    function switchWorkspace(target) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + target + " })")
    }

    function cycleWorkspace(direction) {
        Hyprland.dispatch(direction > 0 ? 'hl.dsp.focus({ workspace = "e+1" })'
                                        : 'hl.dsp.focus({ workspace = "e-1" })')
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

    // ── CENTER: vinyl + camera left of time, alarm + planner right ──
    // One centered row: launcher, workspaces, [gap] vinyl camera TIME alarm
    // calendar [gap] bell wifi bluetooth battery. Time sits dead center.
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
        height: Theme.barHeight
        spacing: 4
        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.icon("camera-photo-symbolic")
            onClicked: SysState.toggleCaptureBoard()
        }
        PillButton {
            id: clockPill
            property string timeText: {
                SysState.clock.seconds          // per-second refresh dependency
                return Qt.formatTime(new Date(), "h:mm AP")
            }
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            label: timeText
            active: SysState.hubOpen
            onClicked: SysState.toggleHub()
        }
        StatusIcon {
            id: alarmBtn
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.icon("alarm-symbolic")
            tint: SysState.reminders.length > 0 ? Theme.accent : Theme.foreground
            onClicked: SysState.toggleReminders()
            Connections {
                target: SysState
                function onRemindersChanged() { alarmBtn.pulse() }
            }
        }
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

            // Bell — unread count, opens the notification center.
            Rectangle {
                id: bellBtn
                width: SysState.notifUnread > 0 ? 32 : 18
                height: 18
                radius: 9
                color: bellMa.containsMouse
                    ? (statusPill.color === Theme.accent ? Theme.hoverStrong : Theme.hover)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    WhiteIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 12
                        source: Theme.icon("preferences-system-notifications-symbolic")
                        tint: statusPill.color === Theme.accent ? Theme.accentText
                            : SysState.notifUnread > 0 ? Theme.accent : Theme.foreground
                    }
                    Text {
                        visible: SysState.notifUnread > 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: SysState.notifUnread > 9 ? "9+" : String(SysState.notifUnread)
                        color: statusPill.color === Theme.accent ? Theme.accentText : Theme.accent
                        font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                    }
                }
                MouseArea { id: bellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.toggleNotifs() }
            }

            // Network — click opens the Wi-Fi panel.
            // Dim when offline entirely (no SSID and no wire) so the
            // radio-on-but-disconnected state reads differently from Off.
            StatusIcon {
                id: netBtn
                source: Theme.icon(bar.netIcon)
                tint: (SysState.wifiSsid === "" && !SysState.wired)
                    ? Theme.dimText
                    : (statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground)
                onClicked: SysState.toggleWifi()
                Connections {
                    target: SysState
                    function onWifiSsidChanged() { netBtn.pulse() }
                    function onWifiEnabledChanged() { netBtn.pulse() }
                    function onWiredChanged() { netBtn.pulse() }
                }
            }

            // Bluetooth — click opens the devices panel
            StatusIcon {
                id: btBtn
                source: Theme.icon(SysState.btPowered ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic")
                tint: SysState.btConnected.length > 0 ? Theme.green
                    : (statusPill.color === Theme.accent ? Theme.accentText : Theme.foreground)
                onClicked: SysState.toggleBluetooth()
                Connections {
                    target: SysState
                    function onBtConnectedChanged() { btBtn.pulse() }
                }
            }

            // Battery — rightmost, click opens Quick Settings
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

            // Night light moon — only up while the warm shader is on.
            // Clicking it turns the warmth back off. Trails the row.
            StatusIcon {
                id: moonBtn
                visible: SysState.nightLight
                source: Theme.icon("weather-clear-night-symbolic")
                tint: statusPill.color === Theme.accent ? Theme.accentText : Theme.yellow
                onClicked: SysState.setNightLight(false)
                Connections {
                    target: SysState
                    function onNightLightChanged() { if (SysState.nightLight) moonBtn.pulse() }
                }
            }

        }
    }
}