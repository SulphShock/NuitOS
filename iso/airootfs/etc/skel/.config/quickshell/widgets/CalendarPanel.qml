// Calendar. Month grid, Monday-first. Today is accent, tap a day to select.
// See NOTICE.md for sources.
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.background
    focus: visible
    MouseArea { anchors.fill: parent }

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property var selectedDate: new Date()

    readonly property var cells: {
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

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            const d = new Date()
            viewYear = d.getFullYear()
            viewMonth = d.getMonth() + 1
            selectedDate = d
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
    Keys.onLeftPressed: shiftMonth(-1)
    Keys.onRightPressed: shiftMonth(1)
    Keys.onHomePressed: goToday()

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

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Calendar"
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

        Text {
            Layout.fillWidth: true
            text: {
                SysState.clock.seconds
                return Qt.formatDate(new Date(), "dddd, MMMM d")
            }
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
        }

        RowLayout {
            Layout.fillWidth: true
            NavBtn { glyph: "‹"; onActivated: panel.shiftMonth(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: new Date(panel.viewYear, panel.viewMonth - 1, 1)
                      .toLocaleDateString(Qt.locale(), "MMMM yyyy")
                color: Theme.text
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
                    Layout.preferredHeight: 36
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

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.formatDate(panel.selectedDate, "ddd, MMM d")
            color: Theme.faintText
            font { family: Theme.fontFamily; pixelSize: 11 }
        }
    }
}
