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
                    Text { text: modelData.secured ? "▣" : "□"; color: modelData.connected ? Theme.green : Theme.dimText; font.pixelSize: 13 }
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
            radius: Theme.radiusSm
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
    }
}
