import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 760
    implicitHeight: 560
    radius: Theme.radiusLg
    color: Theme.menuBg
    MouseArea { anchors.fill: parent }

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

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        text: {
            SysState.clock.seconds
            const now = new Date()
            return Qt.formatTime(now, "h:mm AP") + "  ·  " + Qt.formatDate(now, "dddd, MMMM d")
        }
        color: Theme.text
        font { family: Theme.fontFamily; pixelSize: 13; bold: true }
    }

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property var selectedDate: new Date()

    readonly property var cells: {
        const cells = []
        const first = new Date(viewYear, viewMonth - 1, 1)
        const offset = (first.getDay() + 6) % 7            // Monday-first (GNOME)
        const start = new Date(viewYear, viewMonth - 1, 1 - offset)
        const today = new Date()
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            cells.push({
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth - 1,
                isToday: d.toDateString() === today.toDateString(),
                isSelected: selectedDate.toDateString() === d.toDateString(),
                date: d
            })
        }
        return cells
    }

    function shiftMonth(delta) {
        let m = viewMonth + delta, y = viewYear
        if (m < 1) { m = 12; y-- } else if (m > 12) { m = 1; y++ }
        viewYear = y; viewMonth = m
    }

    component NavBtn: Rectangle {
        id: nb
        property string glyph
        signal activated()
        implicitWidth: 30; implicitHeight: 30; radius: 15
        color: nma.containsMouse ? Theme.hover : "transparent"
        Text { anchors.centerIn: parent; text: nb.glyph; color: Theme.text; font.pixelSize: 15 }
        MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; onClicked: nb.activated() }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.bottomMargin: 18
        anchors.topMargin: 50
        spacing: 18

        // ────────────── Notifications pane ──────────────
        ColumnLayout {
            Layout.preferredWidth: 350
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Notifications"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 15; bold: true }
                }
                Item { Layout.fillWidth: true }
                Rectangle {   // Do Not Disturb
                    width: dndRow.implicitWidth + 20
                    height: 28; radius: 14
                    color: SysState.dnd ? Theme.accent : Theme.inactiveBg
                    Row {
                        id: dndRow
                        anchors.centerIn: parent
                        Text {
                            text: "Do Not Disturb"
                            color: SysState.dnd ? "white" : Theme.text
                            font { family: Theme.fontFamily; pixelSize: 12 }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SysState.dnd = !SysState.dnd
                    }
                }
                Rectangle {   // Clear
                    visible: SysState.notifications.length > 0
                    width: 58; height: 28; radius: 14
                    color: clearMa.containsMouse ? Theme.hover : Theme.inactiveBg
                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 12 }
                    }
                    MouseArea { id: clearMa; anchors.fill: parent; onClicked: SysState.clearNotifications() }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text {
                    visible: SysState.notifications.length === 0
                    anchors.centerIn: parent
                    text: "No Notifications"
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 13 }
                }
                ListView {
                    anchors.fill: parent
                    visible: SysState.notifications.length > 0
                    clip: true
                    spacing: 8
                    model: SysState.notifications
                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180 }
                            NumberAnimation { properties: "scale"; from: 0.94; to: 1; duration: 180; easing.type: Easing.OutCubic }
                        }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { properties: "opacity"; to: 0; duration: 180 }
                            NumberAnimation { properties: "scale"; to: 0.94; duration: 180; easing.type: Easing.InCubic }
                        }
                    }
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: nd.implicitHeight + 20
                        radius: 12
                        color: Theme.inactiveBg
                        Column {
                            id: nd
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 3
                            Row {
                                width: parent.width
                                Text {
                                    width: parent.width - 18
                                    text: modelData.appName
                                    elide: Text.ElideRight
                                    color: Theme.dimText
                                    font { family: Theme.fontFamily; pixelSize: 11 }
                                }
                                Text {
                                    text: "✕"
                                    color: Theme.dimText
                                    font.pixelSize: 11
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: SysState.dismissNotification(modelData)
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                text: modelData.summary
                                wrapMode: Text.Wrap
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: 13; bold: true }
                            }
                            Text {
                                width: parent.width
                                visible: modelData.body !== ""
                                text: modelData.body
                                wrapMode: Text.Wrap
                                color: Theme.dimText
                                font { family: Theme.fontFamily; pixelSize: 12 }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.outline }

        // ────────────── Calendar pane ──────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                NavBtn { glyph: "‹"; onActivated: panel.shiftMonth(-1) }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: new Date(panel.viewYear, panel.viewMonth - 1, 1)
                          .toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 15; bold: true }
                }
                NavBtn { glyph: "›"; onActivated: panel.shiftMonth(1) }
            }

            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.dimText
                        font { family: Theme.fontFamily; pixelSize: 11 }
                    }
                }
            }

            GridLayout {
                columns: 7
                columnSpacing: 6
                rowSpacing: 6
                Layout.fillWidth: true
                Repeater {
                    model: panel.cells
                    delegate: Rectangle {
                        id: dayCell
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 22
                        color: modelData.isToday ? Theme.accent
                             : modelData.isSelected ? Theme.hover
                             : dayMa.containsMouse ? "#22FFFFFF" : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            color: dayCell.modelData.isToday ? "white"
                                 : dayCell.modelData.inMonth ? Theme.text : "#55FFFFFF"
                            font { family: Theme.fontFamily; pixelSize: 12; bold: dayCell.modelData.isToday }
                        }
                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: panel.selectedDate = dayCell.modelData.date
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}