import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: panel
    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible

    onVisibleChanged: if (visible) panelIn.restart()
    NumberAnimation {
        id: panelIn
        target: panel
        property: "opacity"
        from: 0
        to: 1
        duration: 150
        easing.type: Easing.OutCubic
    }

    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)
    Keys.onEscapePressed: {
        if (powerDialog.visible) powerDialog.visible = false
        else SysState.closeAll()
    }

    component QActionButton: Rectangle {
        id: ab
        property string icon
        property bool active: false
        signal activated()
        implicitWidth: 38; implicitHeight: 38; radius: Theme.radiusMd
        color: ab.active ? Theme.hoverStrong
             : am.pressed ? Theme.hoverStrong
             : am.containsMouse ? Theme.hover : "transparent"
        opacity: enabled ? 1 : 0.35
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: panel.actionGlyph(ab.icon)
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 16; bold: true }
        }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ab.activated() }
    }

    // Slim launcher row: opens the dedicated Bluetooth / Wi-Fi panel.
    component DetailRow: Rectangle {
        id: dr
        property string label
        signal opened()
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.radiusSm
        color: drMa.containsMouse ? Theme.hover : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            Text { Layout.fillWidth: true; text: dr.label; color: Theme.dimText; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 10 } }
            Text { text: "›"; color: Theme.dimText; font.pixelSize: 14 }
        }
        MouseArea { id: drMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.opened() }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header ──
        Text {
            Layout.fillWidth: true
            text: "Quick Settings"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 15; bold: true }
        }

        // ── Toggle grid ──
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                QSToggle {
                    Layout.fillWidth: true
                    icon: "network-wireless-symbolic"
                    title: "Wi-Fi"
                    subtitle: SysState.wifiEnabled ? (SysState.wifiSsid || "On") : "Off"
                    active: SysState.wifiEnabled
                    onClicked: SysState.setWifi(!SysState.wifiEnabled)
                }
                DetailRow {
                    label: SysState.wifiSsid === "" ? "Wi-Fi networks" : SysState.wifiSsid
                    onOpened: SysState.toggleWifi()
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                QSToggle {
                    Layout.fillWidth: true
                    icon: SysState.btPowered ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
                    title: "Bluetooth"
                    subtitle: SysState.btPowered ? (SysState.btConnected.length > 0 ? SysState.btConnected.length + " connected" : SysState.btDevices.length > 0 ? SysState.btDevices.length + " devices" : "Ready") : "Off"
                    active: SysState.btPowered
                    onClicked: SysState.setBluetooth(!SysState.btPowered)
                }
                DetailRow {
                    label: SysState.btConnected.length > 0 ? SysState.btConnected[0].name + (SysState.btConnected.length > 1 ? " +" + (SysState.btConnected.length - 1) : "") : "Bluetooth devices"
                    onOpened: SysState.toggleBluetooth()
                }
            }
            QSToggle {
                Layout.fillWidth: true
                filled: true
                icon: panel.volIconName()
                title: "Volume"
                subtitle: SysState.muted ? "Muted" : Math.round(SysState.volume * 100) + "%"
                value: SysState.volume
                fillColor: Theme.blue
                active: !SysState.muted
                onClicked: SysState.toggleMute()
                onWheelAdjusted: direction => SysState.setVolume(SysState.volume + direction * 0.05)
            }
            QSToggle {
                Layout.fillWidth: true
                filled: true
                icon: "display-brightness-symbolic"
                title: "Brightness"
                subtitle: Math.round(SysState.brightness * 100) + "%"
                value: SysState.brightness
                fillColor: Theme.blue
                active: true
                onClicked: SysState.setBrightness(SysState.brightness > 0.5 ? 0.3 : 0.8)
                onWheelAdjusted: direction => SysState.setBrightness(SysState.brightness + direction * 0.05)
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "night-light-symbolic"
                title: "Night Light"
                subtitle: SysState.nightLight ? "On" : "Off"
                active: SysState.nightLight
                onClicked: SysState.setNightLight(!SysState.nightLight)
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "power-profile-balanced-symbolic"
                customGlyph: panel.powerGlyph()
                title: "Power mode"
                subtitle: SysState.powerProfile === "performance" ? "Performance" : SysState.powerProfile === "power-saver" ? "Eco saver" : "Balanced"
                active: true
                onClicked: panel.nextPowerProfile(1)
                onWheelAdjusted: direction => panel.nextPowerProfile(direction)
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "applications-system-symbolic"
                title: "Appearance"
                subtitle: "Customize"
                active: false
                onClicked: SysState.toggleSettings()
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "system-shutdown-symbolic"
                title: "Power"
                subtitle: "Session actions"
                active: true
                activeColor: Theme.danger
                onClicked: {
                    powerDialog.visible = true
                    powerDialog.forceActiveFocus()
                }
            }
        }

        // ── Media (MPRIS) — appears only when a player is active ──
        Rectangle {
            visible: SysState.player !== null
            Layout.fillWidth: true
            implicitHeight: 72
            radius: Theme.radiusMd
            color: Theme.inactiveBg
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12
                Image {
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    visible: SysState.player?.trackArtUrl ?? "" !== ""
                    source: SysState.player?.trackArtUrl ?? ""
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: SysState.player?.trackTitle ?? ""
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 13; bold: true }
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: SysState.player?.trackArtist ?? ""
                        color: Theme.dimText
                        font { family: Theme.fontFamily; pixelSize: 12 }
                    }
                }
                QActionButton {
                    icon: "media-skip-backward-symbolic"
                    enabled: SysState.player?.canGoPrevious ?? false
                    onActivated: SysState.player?.previous()
                }
                QActionButton {
                    icon: SysState.player?.playbackState === MprisPlaybackState.Playing
                          ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                    onActivated: SysState.player?.playPause()
                }
                QActionButton {
                    icon: "media-skip-forward-symbolic"
                    enabled: SysState.player?.canGoNext ?? false
                    onActivated: SysState.player?.next()
                }
            }
        }

    }

    // Shared 4-state volume iconography with TopBar (muted/low/medium/high).
    function volIconName() {
        return SysState.muted || SysState.volume <= 0.01 ? "audio-volume-muted-symbolic"
             : SysState.volume < 0.33 ? "audio-volume-low-symbolic"
             : SysState.volume < 0.66 ? "audio-volume-medium-symbolic"
             : "audio-volume-high-symbolic"
    }

    function powerGlyph() {
        return SysState.powerProfile === "performance" ? "🚀"
            : SysState.powerProfile === "power-saver" ? "🍃" : "🧭"
    }

    function nextPowerProfile(direction) {
        const profiles = ["power-saver", "balanced", "performance"]
        let index = profiles.indexOf(SysState.powerProfile)
        index = (index + direction + profiles.length) % profiles.length
        SysState.setPowerProfile(profiles[index])
    }

    function actionGlyph(name) {
        if (name.startsWith("media-skip-backward")) return "‹"
        if (name.startsWith("media-skip-forward")) return "›"
        if (name.startsWith("media-playback-pause")) return "Ⅱ"
        if (name.startsWith("media-playback")) return "▶"
        if (name.startsWith("applications")) return "⚙"
        if (name.startsWith("system-lock")) return "□"
        if (name.startsWith("system-suspend")) return "Z"
        if (name.startsWith("system-shutdown")) return "⏻"
        return "•"
    }

    // ── Power Off / Reboot dialog (system modal, in-panel) ──
    Rectangle {
        id: powerDialog
        anchors.fill: parent
        radius: Theme.radiusLg
        color: Theme.menuBg
        visible: false
        focus: visible
        Keys.onEscapePressed: {
            visible = false
            panel.forceActiveFocus()
        }
        MouseArea { anchors.fill: parent }   // modal: block everything behind
        component DialogButton: Rectangle {
            id: db
            property string label
            property bool accent: false
            signal activated()
            implicitWidth: 104; implicitHeight: 36; radius: 18
            color: db.accent ? Theme.accent
                 : dma.pressed ? Theme.hoverStrong
                 : (dma.containsMouse ? Theme.hover : Theme.inactiveBg)
            Text {
                anchors.centerIn: parent
                text: db.label
                color: db.accent ? Theme.accentText : Theme.text
                font { family: Theme.fontFamily; pixelSize: 13; bold: true }
            }
            MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: db.activated() }
        }
        Column {
            anchors.centerIn: parent
            spacing: 20
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Image {
                    width: 30; height: 30
                    source: Qt.resolvedUrl("../assets/Logo.png")
                    fillMode: Image.PreserveAspectFit
                }
                Column {
                    Text { text: "Session"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 16; bold: true } }
                    Text { text: "User: " + SysState.username; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 11 } }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Choose a session action"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 13 }
            }
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                columnSpacing: 8
                rowSpacing: 8
                DialogButton { label: "Restart"; onActivated: SysState.reboot() }
                DialogButton { label: "Logout"; onActivated: SysState.logout() }
                DialogButton { label: "Screensaver"; onActivated: SysState.lock() }
                DialogButton { label: "Shutdown"; accent: true; onActivated: SysState.powerOff() }
                DialogButton { label: "Suspend"; onActivated: SysState.suspend() }
            }
        }
    }
}