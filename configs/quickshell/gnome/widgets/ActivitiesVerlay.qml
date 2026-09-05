import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io
import Quickshell.Widgets
import ".."

Rectangle {
    id: overlay
    color: "#E6202020"

    property var apps: []
    property bool appsLoaded: false
    property int selectedIndex: 0
    readonly property var filteredApps:
        apps.filter(a => a.name.toLowerCase().includes(search.text.toLowerCase()))
            .sort((a, b) => a.name.localeCompare(b.name))

    Process {
        id: appLister
        command: ["sh", Qt.resolvedUrl("../lib/listapps.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split("\t")
                if (p.length >= 2 && !overlay.apps.some(a => a.name === p[0]))
                    overlay.apps = overlay.apps.concat([{ name: p[0], exec: p[1], icon: p[2] ?? "" }])
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            if (!appsLoaded) { appsLoaded = true; appLister.running = true }
            search.text = ""
            selectedIndex = 0
            search.forceActiveFocus()
        }
    }

    function launchSelected() {
        if (filteredApps.length > 0)
            SysState.launch(filteredApps[Math.min(selectedIndex, filteredApps.length - 1)].exec)
    }

    MouseArea { anchors.fill: parent; onClicked: SysState.actOpen = false }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 90
        }
        spacing: 24
        width: Math.min(900, overlay.width - 160)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Image {
                width: 42
                height: 42
                source: Qt.resolvedUrl("../assets/Logo.png")
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                scale: logoMa.containsMouse ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                MouseArea { id: logoMa; anchors.fill: parent; hoverEnabled: true }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Activities"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 18; bold: true }
            }
        }

        TextField {
            id: search
            width: Math.min(560, parent.width)
            height: 46
            anchors.horizontalCenter: parent.horizontalCenter
            font { family: Theme.fontFamily; pixelSize: 14 }
            color: Theme.text
            placeholderText: "Type to search"
            placeholderTextColor: "#99FFFFFF"
            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 18; rightPadding: 18
            background: Rectangle {
                radius: height / 2
                color: "#33FFFFFF"
                border.color: search.activeFocus ? "#66FFFFFF" : "#22FFFFFF"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 140 } }
            }
            Keys.onEscapePressed: SysState.actOpen = false
            Keys.onUpPressed: if (overlay.filteredApps.length > 0)
                overlay.selectedIndex = Math.max(0, overlay.selectedIndex - 1)
            Keys.onDownPressed: if (overlay.filteredApps.length > 0)
                overlay.selectedIndex = Math.min(overlay.filteredApps.length - 1, overlay.selectedIndex + 1)
            Keys.onReturnPressed: overlay.launchSelected()
        }

        Flow {
            width: parent.width
            spacing: 8
            visible: overlay.filteredApps.length > 0
            Repeater {
                model: overlay.filteredApps
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    width: 116
                    height: 116
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: cellMa.containsMouse || index === overlay.selectedIndex ? Theme.hover : "transparent"
                        border.color: index === overlay.selectedIndex ? Theme.accent : "transparent"
                        border.width: index === overlay.selectedIndex ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        IconImage {
                            implicitSize: 64
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: cell.modelData.icon.startsWith("/")
                                ? "file://" + cell.modelData.icon
                                : Theme.icon(cell.modelData.icon || "application-x-executable-symbolic")
                        }
                        Text {
                            width: 110
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: cell.modelData.name
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 12 }
                        }
                    }
                    MouseArea {
                        id: cellMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            overlay.selectedIndex = index
                            SysState.launch(cell.modelData.exec)
                        }
                    }
                }
            }
        }

        Text {
            visible: overlay.filteredApps.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: search.text === "" ? "Loading applications..." : "No applications found"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 13 }
        }
    }
}