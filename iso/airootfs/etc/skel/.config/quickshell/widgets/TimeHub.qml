// Time hub. Calendar beside the music player. Opens from the bar clock.
// Local time only. See NOTICE.md for sources.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: panel
    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: contentRow.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.background
    focus: visible
    MouseArea { anchors.fill: parent }

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property var selectedDate: new Date()

    readonly property var cells: {
        evRev                 // event-store revision dependency
        const out = []
        const first = new Date(viewYear, viewMonth - 1, 1)
        const offset = (first.getDay() + 6) % 7
        const start = new Date(viewYear, viewMonth - 1, 1 - offset)
        const today = new Date()
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth - 1,
                isToday: d.toDateString() === today.toDateString(),
                isSelected: selectedDate.toDateString() === d.toDateString(),
                hasEvent: ((dateEvents[dateKey(d)] || []).length > 0),
                date: d
            })
        }
        return out
    }

    function shiftMonth(delta) {
        let m = viewMonth + delta, y = viewYear
        if (m < 1) { m = 12; y-- } else if (m > 12) { m = 1; y++ }
        viewYear = y
        viewMonth = m
    }
    function goToday() {
        const d = new Date()
        viewYear = d.getFullYear()
        viewMonth = d.getMonth() + 1
        selectedDate = d
    }

    // Events live in ~/.local/share/nuit/calendar-events.json as
    // { "2026-9-11": ["Dentist 10:00"] }. Dots mark days that have any.
    function dateKey(d) {
        return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate()
    }
    property int evRev: 0
    property var dateEvents: ({})
    readonly property string selKey: dateKey(selectedDate)
    readonly property var selEvents: dateEvents[selKey] ?? []
    function saveEvents() {
        evWrite.path = (Quickshell.env("HOME") || "/home/user") + "/.local/share/nuit/calendar-events.json"
        evWrite.setText(JSON.stringify(dateEvents))
        evRev++
    }
    function addEvent() {
        const t = (evField.text || "").trim()
        if (t === "") return
        const cur = (dateEvents[selKey] || []).slice()
        cur.push(t)
        const next = Object.assign({}, dateEvents)
        next[selKey] = cur
        dateEvents = next
        evField.text = ""
        saveEvents()
    }
    function delEvent(i) {
        const cur = (dateEvents[selKey] || []).slice()
        cur.splice(i, 1)
        const next = Object.assign({}, dateEvents)
        if (cur.length === 0) delete next[selKey]
        else next[selKey] = cur
        dateEvents = next
        saveEvents()
    }

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            goToday()
            evLoad.reload()
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

    Keys.onEscapePressed: SysState.closeAll()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Left) { shiftMonth(-1); event.accepted = true }
        else if (event.key === Qt.Key_Right) { shiftMonth(1); event.accepted = true }
        else if (event.key === Qt.Key_Home) { goToday(); event.accepted = true }
    }

    component NavBtn: Rectangle {
        id: nb
        property string glyph
        signal activated()
        implicitWidth: 30
        implicitHeight: 30
        radius: height / 2
        color: nma.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            anchors.centerIn: parent
            text: nb.glyph
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 15 }
        }
        MouseArea {
            id: nma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nb.activated()
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ColumnLayout {
            Layout.preferredWidth: 336
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: {
                        SysState.clock.seconds
                        return Qt.formatDate(new Date(), "dddd, MMMM d")
                    }
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 15; bold: true }
                }
                Rectangle {
                    implicitWidth: 62
                    implicitHeight: 26
                    radius: height / 2
                    color: todayMa.containsMouse ? Theme.hover : Theme.inactiveBg
                    Text {
                        anchors.centerIn: parent
                        text: "Today"
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                    }
                    MouseArea {
                        id: todayMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.goToday()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                NavBtn { glyph: "‹"; onActivated: panel.shiftMonth(-1) }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: new Date(panel.viewYear, panel.viewMonth - 1, 1)
                          .toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 13; bold: true }
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
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 6
                rowSpacing: 6
                Repeater {
                    model: panel.cells
                    delegate: Rectangle {
                        id: dayCell
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: height / 2
                        color: modelData.isToday ? Theme.accent
                             : modelData.isSelected ? Theme.hoverStrong
                             : dayMa.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            color: dayCell.modelData.isToday ? Theme.accentText
                                 : dayCell.modelData.inMonth ? Theme.text : Theme.ghostText
                            font { family: Theme.fontFamily; pixelSize: 12; bold: dayCell.modelData.isToday }
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
                            width: 4
                            height: 4
                            radius: 2
                            visible: dayCell.modelData.hasEvent
                            color: dayCell.modelData.isToday ? Theme.accentText : Theme.accent
                        }
                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.selectedDate = dayCell.modelData.date
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.outline }

            // Events on the selected day. Click a dotted day to see them.
            Text {
                Layout.fillWidth: true
                text: "Events · " + Qt.formatDate(panel.selectedDate, "ddd, MMM d")
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 12; bold: true }
            }
            Text {
                visible: panel.selEvents.length === 0
                text: "Nothing here — add one below"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 11 }
            }
            ListView {
                visible: panel.selEvents.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(120, contentHeight)
                clip: true
                spacing: 4
                model: panel.selEvents
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 32
                    radius: Theme.radiusSm
                    color: Theme.inactiveBg
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 12 }
                        }
                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: Theme.radiusSm
                            color: evDelMa.containsMouse ? Theme.danger : "transparent"
                            Text { anchors.centerIn: parent; text: "✕"; color: Theme.text; font.pixelSize: 11 }
                            MouseArea {
                                id: evDelMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: panel.delEvent(index)
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: evField
                    Layout.fillWidth: true
                    placeholderText: "Add event…"
                    font.family: Theme.fontFamily
                    color: Theme.text
                    placeholderTextColor: Theme.dimText
                    background: Rectangle {
                        radius: Theme.radiusSm
                        color: Theme.inactiveBg
                        border.color: evField.activeFocus ? Theme.accent : Theme.outline
                        border.width: 1
                    }
                    Keys.onReturnPressed: panel.addEvent()
                }
                Rectangle {
                    implicitWidth: 62
                    implicitHeight: 30
                    radius: height / 2
                    color: evAddMa.containsMouse ? Theme.hoverStrong : Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "Add"
                        color: Theme.accentText
                        font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                    }
                    MouseArea {
                        id: evAddMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.addEvent()
                    }
                }
            }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.outline }

        YouTubeMusic {
            Layout.fillHeight: true
            radius: 0
        }
    }

    FileView {
        id: evLoad
        path: (Quickshell.env("HOME") || "/home/user") + "/.local/share/nuit/calendar-events.json"
        watchChanges: true
        onLoaded: {
            try {
                const obj = JSON.parse(text)
                if (obj && typeof obj === "object") dateEvents = obj
            } catch (e) { dateEvents = ({}) }
            evRev++
        }
    }
    FileView {
        id: evWrite
        atomicWrites: true
    }
}
