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
    property bool bluetoothExpanded: false
    property string wifiPassword: ""
    property string selectedSsid: ""

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
        implicitWidth: 38; implicitHeight: 38; radius: 12
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
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: ab.activated() }
    }

    // Animated expanding flyout shell (used by the Wi-Fi and Bluetooth rows)
    component ExpandPanel: Rectangle {
        id: ep
        property bool expanded: false
        default property alias contents: epCol.children
        Layout.fillWidth: true
        Layout.preferredHeight: ep.expanded ? epCol.implicitHeight + 20 : 0
        clip: true
        radius: Theme.radiusMd
        color: Theme.inactiveBg
        opacity: ep.expanded ? 1 : 0
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
        ColumnLayout {
            id: epCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 8
        }
    }

    // Spinning refresh glyph while a scan is in progress
    component SpinRefresh: Text {
        id: spinItem
        property bool spinning: false
        text: "↻"
        color: Theme.text
        font.pixelSize: 16
        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 700
            loops: Animation.Infinite
            easing.type: Easing.Linear
            running: spinItem.spinning
            onStopped: spinItem.rotation = 0
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header ──
        Text {
            Layout.fillWidth: true
            text: "QuickSettings"
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
                    onClicked: {
                        if (!SysState.wifiEnabled) SysState.setWifi(true)
                        wifiExpanded = !wifiExpanded
                        if (wifiExpanded) SysState.scanWifi()
                    }
                }
                ExpandPanel {
                    expanded: panel.wifiExpanded
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "🛜"; color: Theme.text; font.pixelSize: 20 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: SysState.wifiSsid === "" ? "Wi-Fi networks" : SysState.wifiSsid
                                    color: Theme.text
                                    font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                                }
                                Text {
                                    text: SysState.wifiSsid === "" ? "Choose a network to connect" : "Connected"
                                    color: SysState.wifiSsid === "" ? Theme.dimText : Theme.green
                                    font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                SpinRefresh {
                                    anchors.centerIn: parent
                                    spinning: SysState.wifiScanning
                                }
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
                                    Text { text: modelData.secured ? "▣" : "□"; color: modelData.connected ? Theme.green : Theme.dimText }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text { Layout.fillWidth: true; text: modelData.ssid; color: Theme.text; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 11; bold: modelData.connected } }
                                        Text { text: modelData.connected ? "Connected" : modelData.secured ? "Secured network" : "Open network"; color: modelData.connected ? Theme.green : Theme.dimText; font { family: Theme.fontFamily; pixelSize: 9 } }
                                    }
                                    Text { text: modelData.strength > 75 ? "▂▄▆█" : modelData.strength > 50 ? "▂▄▆" : modelData.strength > 25 ? "▂▄" : "▂"; color: modelData.connected ? Theme.green : Theme.blue; font.pixelSize: 10 }
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
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                QSToggle {
                    Layout.fillWidth: true
                    icon: SysState.btPowered ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
                    title: "Bluetooth"
                    subtitle: SysState.btPowered ? (SysState.btDevices.length > 0 ? SysState.btDevices.length + " devices" : "Ready") : "Off"
                    active: SysState.btPowered
                    onClicked: {
                        if (!SysState.btPowered) SysState.setBluetooth(true)
                        bluetoothExpanded = !bluetoothExpanded
                        if (bluetoothExpanded) SysState.scanBluetooth()
                    }
                }
                ExpandPanel {
                    expanded: panel.bluetoothExpanded
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { text: "Bluetooth devices"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 11; bold: true } }
                                Text { text: SysState.btConnectedAddresses.length > 0 ? SysState.btConnectedAddresses.length + " connected" : "Ready to connect"; color: SysState.btConnectedAddresses.length > 0 ? Theme.green : Theme.dimText; font { family: Theme.fontFamily; pixelSize: 9; bold: true } }
                            }
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                SpinRefresh {
                                    anchors.centerIn: parent
                                    spinning: SysState.bluetoothScanning
                                    color: Theme.accent
                                }
                                MouseArea { anchors.fill: parent; onClicked: SysState.scanBluetooth() }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(140, contentHeight)
                            visible: SysState.btDevices.length > 0
                            clip: true
                            model: SysState.btDevices
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width
                                height: 34
                                radius: 9
                                color: btMouse.containsMouse ? Theme.hover : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: "ᛒ"; color: SysState.btConnectedAddresses.indexOf(modelData.address) >= 0 ? Theme.green : Theme.foreground; font.pixelSize: 15 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text { Layout.fillWidth: true; text: modelData.name; color: Theme.text; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 11; bold: true } }
                                        Text { Layout.fillWidth: true; text: SysState.btConnectedAddresses.indexOf(modelData.address) >= 0 ? "Connected" : modelData.address; color: SysState.btConnectedAddresses.indexOf(modelData.address) >= 0 ? Theme.green : Theme.dimText; font { family: Theme.fontFamily; pixelSize: 9 } }
                                    }
                                    Text { text: SysState.btConnectedAddresses.indexOf(modelData.address) >= 0 ? "Connected" : "Connect"; color: SysState.btConnectedAddresses.indexOf(modelData.address) >= 0 ? Theme.green : Theme.accent; font { family: Theme.fontFamily; pixelSize: 9; bold: true } }
                                }
                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SysState.connectBluetooth(modelData.address)
                                }
                            }
                        }
                        Text {
                            visible: SysState.btDevices.length === 0
                            text: "No paired devices found"
                            color: Theme.dimText
                            font { family: Theme.fontFamily; pixelSize: 10 }
                        }
                        Text {
                            visible: SysState.btError !== ""
                            text: SysState.btError
                            color: "#FF8A8A"
                            font { family: Theme.fontFamily; pixelSize: 10 }
                        }
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
                onWheelAdjusted: SysState.setVolume(SysState.volume + direction * 0.05)
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
                 : dma.pressed ? Theme.hoverStrong
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
                DialogButton { label: "Suspend"; onActivated: SysState.suspend() }
            }
        }
    }
}