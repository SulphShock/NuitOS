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
    property bool wifiExpanded: false
    property string wifiPassword: ""
    property string selectedSsid: ""

    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)
    Keys.onEscapePressed: {
        if (powerDialog.visible) powerDialog.visible = false
        else SysState.closeAll()
    }

    component QActionButton: Rectangle {
        id: ab
        property string icon
        signal activated()
        implicitWidth: 38; implicitHeight: 38; radius: 12
        color: am.pressed ? Theme.hoverStrong : am.containsMouse ? Theme.hover : "transparent"
        opacity: enabled ? 1 : 0.35
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: panel.actionGlyph(ab.icon)
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 16; bold: true }
        }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: ab.activated() }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

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
                    onClicked: {
                        if (!SysState.wifiEnabled) SysState.setWifi(true)
                        wifiExpanded = !wifiExpanded
                        if (wifiExpanded) SysState.scanWifi()
                    }
                }
                Rectangle {
                    id: wifiFlyout
                    visible: panel.wifiExpanded
                    Layout.fillWidth: true
                    implicitHeight: wifiCol.implicitHeight + 20
                    radius: Theme.radiusMd
                    color: Theme.inactiveBg
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    ColumnLayout {
                        id: wifiCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "🛜"; color: Theme.text; font.pixelSize: 20 }
                            Text {
                                Layout.fillWidth: true
                                text: SysState.wifiSsid === "" ? "Wi-Fi networks" : SysState.wifiSsid + "  Connected"
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                            }
                            Text {
                                text: "↻"
                                color: Theme.text
                                font.pixelSize: 16
                                MouseArea { anchors.fill: parent; onClicked: SysState.scanWifi() }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(150, contentHeight)
                            visible: SysState.wifiNetworks.length > 0
                            clip: true
                            model: SysState.wifiNetworks
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 32
                                radius: 8
                                color: modelData.connected ? Theme.hover : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: modelData.secured ? "▣" : "□"; color: Theme.dimText }
                                    Text { Layout.fillWidth: true; text: modelData.ssid; color: Theme.text; elide: Text.ElideRight; font.pixelSize: 11 }
                                    Text { text: modelData.strength + "%"; color: Theme.dimText; font.pixelSize: 10 }
                                    MouseArea { anchors.fill: parent; onClicked: { selectedSsid = modelData.ssid; wifiPassword = "" } }
                                }
                            }
                        }
                        TextField {
                            Layout.fillWidth: true
                            visible: selectedSsid !== ""
                            placeholderText: "Password for " + selectedSsid
                            echoMode: TextInput.Password
                            text: wifiPassword
                            onTextChanged: wifiPassword = text
                            font.family: Theme.fontFamily
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            visible: selectedSsid !== ""
                            implicitHeight: 30
                            radius: 10
                            color: Theme.accent
                            Text { anchors.centerIn: parent; text: "Connect"; color: "white"; font.pixelSize: 11; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: { SysState.connectWifi(selectedSsid, wifiPassword); selectedSsid = "" } }
                        }
                        Text {
                            visible: SysState.wifiError !== ""
                            text: SysState.wifiError
                            color: "#FF8A8A"
                            font.pixelSize: 10
                        }
                    }
                }
            }
            QSToggle {
                Layout.fillWidth: true
                icon: SysState.btPowered ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
                title: "Bluetooth"
                subtitle: SysState.btPowered ? "On" : "Off"
                active: SysState.btPowered
                onClicked: SysState.setBluetooth(!SysState.btPowered)
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "audio-volume-high-symbolic"
                title: "Volume"
                subtitle: SysState.muted ? "Muted" : Math.round(SysState.volume * 100) + "%"
                active: !SysState.muted
                onClicked: SysState.toggleMute()
                onWheelAdjusted: SysState.setVolume(SysState.volume + direction * 0.05)
            }
            QSToggle {
                Layout.fillWidth: true
                icon: "display-brightness-symbolic"
                title: "Brightness"
                subtitle: Math.round(SysState.brightness * 100) + "%"
                active: true
                onClicked: SysState.setBrightness(SysState.brightness > 0.5 ? 0.3 : 0.8)
                onWheelAdjusted: SysState.setBrightness(SysState.brightness + direction * 0.05)
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
                onWheelAdjusted: panel.nextPowerProfile(direction)
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
                activeColor: "#8F2020"
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

    function volIconName() {
        return SysState.muted || SysState.volume <= 0.01 ? "audio-volume-muted-symbolic"
             : SysState.volume < 0.5 ? "audio-volume-medium-symbolic"
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
                 : (dma.containsMouse ? Theme.hover : Theme.inactiveBg)
            Text {
                anchors.centerIn: parent
                text: db.label
                color: db.accent ? "white" : Theme.text
                font { family: Theme.fontFamily; pixelSize: 13; bold: true }
            }
            MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; onClicked: db.activated() }
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
            }
        }
    }
}