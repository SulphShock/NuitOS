import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible
    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            SysState.refreshBt()
            SysState.scanBluetooth()
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

    // One section block reused three times. Items carry
    // {address, name, action}; the tap label follows the action.
    component BtSection: ColumnLayout {
        id: sec
        property string title
        property int count: 0
        property var model: []
        property string emptyText
        Layout.fillWidth: true
        spacing: 4
        Text {
            text: sec.title + (sec.count > 0 ? " (" + sec.count + ")" : "")
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(108, contentHeight)
            visible: sec.count > 0
            clip: true
            spacing: 1
            model: sec.model
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 34
                radius: Theme.radiusSm
                property bool isLive: modelData.action === "disconnect"
                color: rowMa.containsMouse ? Theme.hover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text { text: "ᛒ"; color: isLive ? Theme.green : Theme.foreground; font.pixelSize: 15 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { Layout.fillWidth: true; text: modelData.name; color: Theme.text; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 11; bold: true } }
                        Text { Layout.fillWidth: true; text: isLive ? "Connected" : modelData.address; color: isLive ? Theme.green : Theme.dimText; font { family: Theme.fontFamily; pixelSize: 9 } }
                    }
                    Text {
                        text: modelData.action === "disconnect" ? "Connected" : modelData.action === "pair" ? "Pair" : "Connect"
                        color: isLive ? Theme.green : Theme.accent
                        font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                    }
                }
                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysState.btAction(modelData.address, modelData.action)
                }
            }
        }
        Text {
            visible: sec.count === 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: sec.emptyText
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 10 }
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Bluetooth"
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
                color: SysState.btPowered ? (powMa.containsMouse ? Theme.hoverStrong : Theme.accent)
                                          : (powMa.containsMouse ? Theme.hover : Theme.inactiveBg)
                Text {
                    anchors.centerIn: parent
                    text: SysState.btPowered ? "On" : "Off"
                    color: SysState.btPowered ? Theme.accentText : Theme.text
                    font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                }
                MouseArea { id: powMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.setBluetooth(!SysState.btPowered) }
            }
            Rectangle {
                implicitWidth: 110
                implicitHeight: 32
                radius: Theme.radiusMd
                color: rsMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text {
                    anchors.centerIn: parent
                    text: SysState.bluetoothScanning ? "Scanning…" : "Rescan"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 12 }
                }
                MouseArea { id: rsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.scanBluetooth() }
            }
        }

        Text {
            visible: SysState.btError !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: SysState.btError
            color: Theme.error
            font { family: Theme.fontFamily; pixelSize: 11 }
        }

        BtSection {
            title: "Connected"
            count: SysState.btConnected.length
            model: SysState.btConnected
            emptyText: "Nothing connected"
        }
        BtSection {
            title: "Paired"
            count: SysState.btPaired.length
            model: SysState.btPaired
            emptyText: "No paired devices"
        }
        BtSection {
            title: "Available"
            count: SysState.btAvailable.length
            model: SysState.btAvailable
            emptyText: "Nothing nearby — put the device in pairing mode, then rescan"
        }
    }

}
