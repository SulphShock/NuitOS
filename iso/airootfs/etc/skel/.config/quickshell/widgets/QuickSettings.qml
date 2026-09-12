import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Widgets
import ".."

Rectangle {
    id: panel
    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible

    onVisibleChanged: if (visible) { panelIn.restart(); SysState.maybeRefreshUpdates() }
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
                icon: "power-profile-" + SysState.powerProfile + "-symbolic"
                title: "Power mode"
                subtitle: SysState.powerProfile === "performance" ? "Performance" : SysState.powerProfile === "power-saver" ? "Eco saver" : "Balanced"
                active: true
                onClicked: panel.nextPowerProfile(1)
                onWheelAdjusted: direction => panel.nextPowerProfile(direction)
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
                icon: "view-refresh-symbolic"
                title: "System update"
                subtitle: SysState.updateSubtitle
                active: SysState.pendingUpdates > 0
                onClicked: SysState.runOsUpdate()
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

        // ── Battery: the bar, centered, with time left ──
        // Green at 60+, yellow down to 21, red below that.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Battery"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 11; bold: true }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 10
                radius: 5
                color: Theme.inactiveBg
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * Math.max(0, Math.min(100, SysState.batteryPct)) / 100
                    radius: 5
                    color: SysState.batteryPct >= 60 ? Theme.green
                        : SysState.batteryPct >= 21 ? Theme.yellow : Theme.error
                    Behavior on width { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: SysState.batteryPct + "% " + SysState.batteryEta
                    + (SysState.charging ? " · charging" : "")
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: Theme.fontPxSmall }
            }
        }

    }

    function nextPowerProfile(direction) {
        const profiles = ["power-saver", "balanced", "performance"]
        let index = profiles.indexOf(SysState.powerProfile)
        index = (index + direction + profiles.length) % profiles.length
        SysState.setPowerProfile(profiles[index])
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
                DialogButton { label: "Screensaver"; onActivated: { SysState.closeAll(); SysState.screensaver() } }
                DialogButton { label: "Shutdown"; accent: true; onActivated: SysState.powerOff() }
                DialogButton { label: "Suspend"; onActivated: SysState.suspend() }
            }
        }
    }
}