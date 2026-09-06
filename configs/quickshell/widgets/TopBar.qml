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
    color: Theme.panelBg                       // #1E1E1E @ 95%
    WlrLayershell.namespace: "quickshell:gnome-bar"

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
        return "battery-level-" + Math.round(p / 10) * 10
            + (SysState.charging ? "-charging" : "") + "-symbolic"
    }
    property int workspaceRevision: 0
    readonly property var workspaceIds: {
        workspaceRevision
        const ids = [1, 2, 3, 4, 5]
        for (const workspace of (Hyprland.workspaces?.values ?? [])) {
            if (workspace.id > 5) ids.push(workspace.id)
        }
        return [...new Set(ids)].sort((a, b) => a - b)
    }
    Connections {
        target: Hyprland
        function onRawEvent() { bar.workspaceRevision++ }
    }
    Process { id: workspaceSwitch }

    function switchWorkspace(target) {
        workspaceSwitch.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + String(target) + " })"]
        workspaceSwitch.running = true
    }

    function cycleWorkspace(direction) {
        const target = direction > 0 ? "+1" : "-1"
        workspaceSwitch.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + target + "\" })"]
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
        width: 22; height: 22; radius: 11
        color: mouse.containsMouse
            ? (statusPill.color === Theme.accent ? "#40FFFFFF" : Theme.hover)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        WhiteIcon {
            id: glyph
            anchors.centerIn: parent
            size: 15
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
            width: 26
            height: 26
            radius: 8
            color: logoMouse.containsMouse || SysState.actOpen ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
            Image {
                anchors.centerIn: parent
                width: 20
                height: 20
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
            height: 26
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
                    width: 22
                    height: 22
                    radius: 7
                    color: Hyprland.focusedWorkspace?.id === modelData ? Theme.accent
                        : workspaceMouse.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Hyprland.focusedWorkspace?.id === modelData ? "white" : Theme.dimText
                        font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                    }
                    Rectangle {
                        visible: workspaceButton.occupied
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: 12
                        height: 2
                        radius: 1
                        color: Hyprland.focusedWorkspace?.id === modelData ? "white" : Theme.foreground
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
    }

    // ── CENTER: 12-hour clock ──
    PillButton {
        id: clockPill
        property string timeText: {
            SysState.clock.seconds          // per-second refresh dependency
            const d = new Date()
            return Qt.formatTime(d, "h:mm AP")
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
        width: statusRow.implicitWidth + 20
        height: 26
        radius: height / 2
        color: statusMouse.pressed || SysState.qsOpen ? Theme.accent
             : statusMouse.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            onClicked: SysState.toggleQs()
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 2

            // Network — click to open Quick Settings
            StatusIcon {
                id: netBtn
                source: Theme.icon(bar.netIcon)
                tint: statusPill.color === Theme.accent ? "white" : Theme.foreground
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
                tint: statusPill.color === Theme.accent ? "white" : Theme.foreground
                onClicked: SysState.toggleMute()
                onWheelAdjusted: SysState.setVolume(SysState.volume + direction * 0.05)
                Connections {
                    target: SysState
                    function onMutedChanged() { volBtn.pulse() }
                }
            }

            // Battery — click opens Quick Settings, scroll adjusts brightness
            StatusIcon {
                id: battBtn
                source: Theme.icon(bar.battIcon)
                tint: statusPill.color === Theme.accent ? "white" : Theme.foreground
                onClicked: SysState.toggleQs()
                onWheelAdjusted: SysState.setBrightness(SysState.brightness + direction * 0.05)
                Connections {
                    target: SysState
                    function onChargingChanged() { battBtn.pulse() }
                    function onBrightnessChanged() { battBtn.pulse() }
                }
            }
        }
    }
}