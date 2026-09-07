import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 340
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible

    property string error: ""

    onVisibleChanged: if (visible) { panel.error = ""; SysState.refreshReminders(); panelIn.restart() }
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
    Keys.onEscapePressed: SysState.closeAll()

    component RemButton: Rectangle {
        id: rb
        property string label
        property bool accent: false
        signal activated()
        implicitWidth: 74; implicitHeight: 32; radius: Theme.radiusSm
        color: rb.accent ? Theme.accent
             : rma.pressed ? Theme.hoverStrong
             : (rma.containsMouse ? Theme.hover : Theme.inactiveBg)
        border.color: rb.accent ? Theme.accent : Theme.outline
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: rb.label
            color: rb.accent ? "#1D2021" : Theme.text
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
        }
        MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: rb.activated() }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Reminders"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 15; bold: true }
        }

        // ── Currently set ──
        Text {
            visible: SysState.reminders.length === 0
            text: "Nothing set — add one below"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
        }
        ListView {
            visible: SysState.reminders.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(220, contentHeight)
            clip: true
            spacing: 4
            model: SysState.reminders
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 40
                radius: Theme.radiusSm
                color: Theme.inactiveBg
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData.text
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                        }
                        Text {
                            text: SysState.reminderLabel(modelData.when)
                                + "  ·  " + Qt.formatDateTime(new Date(modelData.when), "h:mm AP")
                            color: Theme.dimText
                            font { family: Theme.fontFamily; pixelSize: 9 }
                        }
                    }
                    Text {
                        text: SysState.clock.seconds  // per-second refresh dependency
                        visible: false
                        font.pixelSize: 1
                    }
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 8
                        color: delMa.containsMouse ? "#CC241D" : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.text; font.pixelSize: 11 }
                        MouseArea {
                            id: delMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SysState.delReminder(modelData.id)
                        }
                    }
                }
            }
        }

        // ── Add new ──
        TextField {
            id: whatField
            Layout.fillWidth: true
            placeholderText: "Remind me to…"
            font.family: Theme.fontFamily
            color: Theme.text
            placeholderTextColor: Theme.dimText
            background: Rectangle {
                radius: Theme.radiusSm
                color: Theme.inactiveBg
                border.color: whatField.activeFocus ? Theme.accent : Theme.outline
                border.width: 1
            }
            Keys.onReturnPressed: panel.submit()
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: whenField
                Layout.fillWidth: true
                placeholderText: "15m · 2h · 14:30"
                font.family: Theme.fontFamily
                color: Theme.text
                placeholderTextColor: Theme.dimText
                background: Rectangle {
                    radius: Theme.radiusSm
                    color: Theme.inactiveBg
                    border.color: whenField.activeFocus ? Theme.accent : Theme.outline
                    border.width: 1
                }
                Keys.onReturnPressed: panel.submit()
            }
            RemButton {
                label: "Add"
                accent: true
                onActivated: panel.submit()
            }
        }
        Text {
            visible: panel.error !== ""
            text: panel.error
            color: "#FB4934"
            font { family: Theme.fontFamily; pixelSize: 10 }
        }
        Text {
            text: "When: 15m · 2h · 1h30m · 14:30"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 9 }
        }
    }

    function submit() {
        if (SysState.addReminder(whatField.text, whenField.text)) {
            whatField.text = ""
            whenField.text = ""
            panel.error = ""
        } else {
            panel.error = "Need text + a time (15m · 2h · 14:30)"
        }
    }
}
