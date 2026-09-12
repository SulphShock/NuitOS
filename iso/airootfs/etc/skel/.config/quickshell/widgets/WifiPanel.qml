import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible
    property string selectedSsid: ""
    property string wifiPassword: ""

    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            selectedSsid = ""
            wifiPassword = ""
            SysState.refreshNetwork()
            SysState.scanWifi()
            SysState.refreshNetExtras()
            SysState.refreshNearby()
        }
    }
    NumberAnimation {
        id: panelIn
        target: panel
        property: "opacity"
        from: 0
        to: 1
        duration: 150
        easing.type: Easing.OutCubic
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Wi-Fi"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 15; bold: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.radiusMd
                color: SysState.wifiEnabled ? (powMa.containsMouse ? Theme.hoverStrong : Theme.accent)
                                            : (powMa.containsMouse ? Theme.hover : Theme.inactiveBg)
                Text {
                    anchors.centerIn: parent
                    text: SysState.wifiEnabled ? (SysState.wifiSsid === "" ? "On" : SysState.wifiSsid) : "Off"
                    elide: Text.ElideRight
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    color: SysState.wifiEnabled ? Theme.accentText : Theme.text
                    font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                }
                MouseArea { id: powMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.setWifi(!SysState.wifiEnabled) }
            }
            Rectangle {
                implicitWidth: 110
                implicitHeight: 32
                radius: Theme.radiusMd
                color: rsMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text {
                    anchors.centerIn: parent
                    text: SysState.wifiScanning ? "Scanning…" : "Rescan"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 12 }
                }
                MouseArea { id: rsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.scanWifi() }
            }
        }

        Text {
            visible: SysState.wifiError !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: SysState.wifiError
            color: Theme.error
            font { family: Theme.fontFamily; pixelSize: 11 }
        }

        Text {
            text: SysState.wifiNetworks.length > 0 ? "Networks (" + SysState.wifiNetworks.length + ")" : "Networks"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(280, contentHeight)
            visible: SysState.wifiNetworks.length > 0
            clip: true
            spacing: 1
            model: SysState.wifiNetworks
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 34
                radius: Theme.radiusSm
                color: modelData.connected ? Theme.hover : netMa.containsMouse ? Theme.hover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text { text: modelData.secured ? "" : ""; color: modelData.connected ? Theme.green : Theme.dimText; font.pixelSize: 13 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { Layout.fillWidth: true; text: modelData.ssid; color: Theme.text; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 11; bold: modelData.connected } }
                        Text { text: modelData.connected ? "Connected" : modelData.secured ? "Secured network" : "Open network"; color: modelData.connected ? Theme.green : Theme.dimText; font { family: Theme.fontFamily; pixelSize: 9 } }
                    }
                    Text { text: modelData.strength > 75 ? "▂▄▆█" : modelData.strength > 50 ? "▂▄▆" : modelData.strength > 25 ? "▂▄" : "▂"; color: modelData.connected ? Theme.green : Theme.blue; font.pixelSize: 10 }
                }
                MouseArea {
                    id: netMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected) return
                        if (modelData.secured) { panel.selectedSsid = modelData.ssid; panel.wifiPassword = "" }
                        else SysState.connectWifi(modelData.ssid, "")
                    }
                }
            }
        }
        Text {
            visible: SysState.wifiNetworks.length === 0 && !SysState.wifiScanning
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "No networks found — rescan or check the radio is on"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 10 }
        }
        TextField {
            Layout.fillWidth: true
            visible: panel.selectedSsid !== ""
            placeholderText: "Password for " + panel.selectedSsid
            echoMode: TextInput.Password
            text: panel.wifiPassword
            onTextChanged: panel.wifiPassword = text
            font.family: Theme.fontFamily
            Keys.onReturnPressed: {
                SysState.connectWifi(panel.selectedSsid, panel.wifiPassword)
                panel.selectedSsid = ""
            }
        }
        Rectangle {
            Layout.fillWidth: true
            visible: panel.selectedSsid !== ""
            implicitHeight: 32
            radius: Theme.radiusMd
            color: connMa.containsMouse ? Theme.hoverStrong : Theme.accent
            Text { anchors.centerIn: parent; text: "Connect"; color: Theme.accentText; font.pixelSize: 11; font.bold: true }
            MouseArea {
                id: connMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SysState.connectWifi(panel.selectedSsid, panel.wifiPassword)
                    panel.selectedSsid = ""
                }
            }
        }

        // Captive portal: connected but staring at a login wall.
        Rectangle {
            visible: SysState.portalSuspected
            Layout.fillWidth: true
            implicitHeight: 44
            radius: Theme.radiusLg
            color: Theme.wellSoft
            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Connected, but the internet may need a sign-in."
                    color: Theme.yellow
                    font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                }
                Rectangle {
                    implicitWidth: 86
                    implicitHeight: 26
                    radius: Theme.radiusMd
                    color: portalMa.containsMouse ? Theme.hoverStrong : Theme.accent
                    Text { anchors.centerIn: parent; text: "Open login"; color: Theme.accentText; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: portalMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.openPortal() }
                }
            }
        }

        // Addresses. Tap any row to copy it.
        component NetRow: Rectangle {
            id: nr
            property string label
            property string value
            Layout.fillWidth: true
            implicitHeight: 28
            radius: Theme.radiusSm
            color: nrMa.containsMouse ? Theme.hover : "transparent"
            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                Text { text: nr.label; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 10 } }
                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: nr.value === "" ? "—" : nr.value; elide: Text.ElideLeft; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 10 } }
            }
            MouseArea { id: nrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: nr.value !== ""; onClicked: SysState.runCmd(["wl-copy", nr.value]) }
        }
        Text { text: "This machine"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 11; bold: true } }
        NetRow { label: "Local IP"; value: SysState.localIp }
        NetRow { label: "Public IP"; value: SysState.publicIp }

        // Who's eating the pipe, live-ish (3s samples, top 5).
        Text {
            visible: SysState.procRows.length > 0
            text: "Bandwidth by process"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
        }
        Repeater {
            model: SysState.procRows
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text { Layout.fillWidth: true; text: modelData.proc; elide: Text.ElideRight; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 10 } }
                Text { text: "↓ " + SysState.fmtRate(modelData.rxRate); color: Theme.green; font { family: Theme.fontFamily; pixelSize: 10 } }
                Text { text: "↑ " + SysState.fmtRate(modelData.txRate); color: Theme.blue; font { family: Theme.fontFamily; pixelSize: 10 } }
            }
        }

        // Neighbors on the LAN, from the ARP table. No scanners, just asking nicely.
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: SysState.nearbyScanning ? "Nearby devices — scanning…" : "Nearby devices"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 11; bold: true }
            }
            Rectangle {
                implicitWidth: 72
                implicitHeight: 24
                radius: Theme.radiusSm
                color: nbMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text { anchors.centerIn: parent; text: "Refresh"; color: Theme.text; font.pixelSize: 10 }
                MouseArea { id: nbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.refreshNearby() }
            }
        }
        Repeater {
            model: SysState.nearbyHosts
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.radiusSm
                color: nbRowMa.containsMouse ? Theme.hover : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    Text { Layout.fillWidth: true; text: modelData.host !== "" ? modelData.host : modelData.ip; elide: Text.ElideRight; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 10 } }
                    Text { text: modelData.ip; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 10 } }
                }
                MouseArea { id: nbRowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.runCmd(["wl-copy", modelData.ip]) }
            }
        }
    }
}
