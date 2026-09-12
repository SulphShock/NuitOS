// Day planner. Markdown day files, calendar on top.
// See NOTICE.md for sources.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import ".."
import "../lib/PlanovaModel.js" as Planova

Rectangle {
    id: panel
    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible
    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    property string orgDir: ""
    property bool orgMissing: false
    property int year: 0
    property int month: 0   // 0-based, like Date
    property string selectedKey: ""
    property string todayKey: Planova.keyForDate(new Date())
    property var dailies: ({})
    property int revision: 0
    property string addType: "todo"   // todo | event | log
    property string refillSel: ""     // JSON of selected refill contents
    property var writeQueue: []
    property bool writeBusy: false

    readonly property var summary: {
        revision
        const c = dailies[selectedKey]
        return c !== undefined ? Planova.daySummary(selectedKey, c) : null
    }
    readonly property var refillTodos: {
        revision
        const arr = []
        for (const k in dailies) arr.push({ key: k, content: dailies[k] })
        return Planova.collectRefillTodos(arr, selectedKey)
    }

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            const d = new Date()
            year = d.getFullYear()
            month = d.getMonth()
            selectedKey = todayKey
            refillSel = ""
            rescan()
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
    Timer {
        interval: 30000; repeat: true
        running: panel.visible
        triggeredOnStart: false
        onTriggered: rescan()
    }

    Process {
        id: scanProc
        stdout: StdioCollector { id: scanOut; waitForEnd: true }
        onExited: code => {
            if (code !== 0) { orgMissing = true; return }
            applyScan(scanOut.text || "")
        }
    }
    function startScan() {
        scanProc.command = ["sh", "-c",
            'org=""; for d in "${NUIT_PLANOVA_ORG:-}" "$HOME/Planova" "$HOME/Org"; do [ -n "$d" ] && [ -d "$d" ] && { org="$d"; break; }; done;'
            + 'printf "ORG:%s\\n" "$org";'
            + '[ -n "$org" ] && mkdir -p "$org/dailies" && cd "$org/dailies" && for f in *.md; do [ -f "$f" ] || continue; printf "\\x1e%s\\n" "$f"; cat -- "$f"; done']
        scanProc.running = true
    }
    function applyScan(text) {
        const lines = text.split("\n")
        const first = lines.length > 0 ? lines[0] : ""
        if (first.indexOf("ORG:") !== 0) { orgMissing = true; return }
        orgDir = first.slice(4)
        if (orgDir === "") { orgMissing = true; return }
        orgMissing = false
        const rest = lines.slice(1).join("\n").split("\x1e")
        const map = {}
        for (const chunk of rest) {
            if (!chunk) continue
            const nl = chunk.indexOf("\n")
            const name = (nl >= 0 ? chunk.slice(0, nl) : chunk).trim()
            const m = name.match(/(\d{8})\.md$/)
            if (!m) continue
            map[m[1]] = nl >= 0 ? chunk.slice(nl + 1) : ""
        }
        dailies = map
        revision++
    }
    // One write at a time through a single FileView -- bursts (refill)
    // queue up instead of racing each other.
    FileView {
        id: dayWrite
        atomicWrites: true
    }
    function writeDaily(key, content) {
        writeQueue = writeQueue.concat([{ key: key, content: content }])
        pumpWrites()
    }
    function pumpWrites() {
        if (writeBusy || writeQueue.length === 0) return
        writeBusy = true
        const w = writeQueue[0]
        writeQueue = writeQueue.slice(1)
        dayWrite.path = orgDir + "/dailies/" + w.key + ".md"
        dayWrite.setText(w.content)
        const cur = dailies
        cur[w.key] = w.content
        dailies = cur
        revision++
        writeBusy = false
        if (writeQueue.length > 0) pumpWrites()
    }
    function baseContent(key) {
        return dailies[key] !== undefined ? dailies[key] : "# Events\n\n# Todos\n\n# Notes\n"
    }
    function toggleTask(lineIndex) {
        const c = baseContent(selectedKey)
        writeDaily(selectedKey, Planova.toggleTaskAtLine(c, lineIndex))
    }
    function commitAdd(title, hh, mm) {
        const t = (title || "").trim()
        if (t === "" || orgMissing) return
        if (addType === "event") {
            let h = parseInt(hh), m = parseInt(mm)
            if (isNaN(h) || isNaN(m)) { h = 9; m = 0 }
            writeDaily(selectedKey, Planova.insertAfterLastEvent(baseContent(selectedKey), Planova.eventLineFor(h, m, t), Planova.DEFAULT_EVENT_HEADER))
        } else if (addType === "log") {
            const d = new Date()
            writeDaily(selectedKey, Planova.insertAtEndOfSection(baseContent(selectedKey), Planova.logLineFor(d.getHours(), d.getMinutes(), t), Planova.DEFAULT_LOG_HEADER))
        } else {
            writeDaily(selectedKey, Planova.insertAfterLastTodo(baseContent(selectedKey), Planova.todoLineFor(t), Planova.DEFAULT_TODO_HEADER))
        }
        addField.text = ""
    }
    function moveMonth(delta) {
        let y = year, m = month + delta
        while (m < 0) { m += 12; y-- }
        while (m > 11) { m -= 12; y++ }
        year = y
        month = m
    }
    function applyRefill() {
        let sel = []
        try { sel = JSON.parse(refillSel || "[]") } catch (e) { sel = [] }
        if (sel.length === 0 || orgMissing) return
        // Group chosen lines by source day, lift them out, drop them today.
        const bySource = {}
        for (const c of sel) {
            const src = refillTodos.filter(r => r.content === c)[0]
            if (!src) continue
            if (!bySource[src.sourceKey]) bySource[src.sourceKey] = []
            bySource[src.sourceKey].push(c)
        }
        for (const src in bySource) {
            if (src === selectedKey) continue
            writeDaily(src, Planova.removeTodoLines(baseContent(src), bySource[src]))
        }
        let target = baseContent(selectedKey)
        for (const c of sel) target = Planova.insertAfterLastTodo(target, c, Planova.DEFAULT_TODO_HEADER)
        writeDaily(selectedKey, target)
        refillSel = ""
    }
    function monthName() {
        return ["January", "February", "March", "April", "May", "June", "July",
            "August", "September", "October", "November", "December"][month]
    }

    function rescan() { startScan() }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Planner"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 15; bold: true }
            }
            Text {
                text: "‹"
                color: railMa.containsMouse ? Theme.text : Theme.dimText
                font.pixelSize: 16
                MouseArea { id: railMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: moveMonth(-1) }
            }
            Text {
                text: monthName() + " " + year
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const d = new Date()
                        year = d.getFullYear()
                        month = d.getMonth()
                        selectedKey = todayKey
                    }
                }
            }
            Text {
                text: "›"
                color: railMa2.containsMouse ? Theme.text : Theme.dimText
                font.pixelSize: 16
                MouseArea { id: railMa2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: moveMonth(1) }
            }
        }

        Text {
            visible: orgMissing
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "No planner folder found — set NUIT_PLANOVA_ORG or create ~/Planova with a dailies/ folder inside."
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
        }

        ColumnLayout {
            visible: !orgMissing
            Layout.fillWidth: true
            spacing: 4
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
                        font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                    }
                }
            }
            Repeater {
                model: Planova.monthGrid(year, month, todayKey, selectedKey)
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: modelData.days
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: Theme.radiusSm
                            color: modelData.selected ? Theme.accent
                                : modelData.today ? Theme.wellSoft
                                : cellMa.containsMouse ? Theme.hover : "transparent"
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.day
                                    color: modelData.selected ? Theme.accentText
                                        : !modelData.inMonth ? Theme.ghostText : Theme.text
                                    font { family: Theme.fontFamily; pixelSize: 10; bold: modelData.today }
                                }
                                Row {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 1
                                    visible: {
                                        const ind = Planova.dayIndicator(panel.summaryFor(modelData.key))
                                        return ind.kind === "dots" || ind.kind === "count" || ind.kind === "eventDot" || ind.kind === "fileDot" || ind.kind === "allDone"
                                    }
                                    Repeater {
                                        model: {
                                            const ind = Planova.dayIndicator(panel.summaryFor(modelData.key))
                                            if (ind.kind === "dots") return ind.count
                                            return 1
                                        }
                                        delegate: Rectangle {
                                            width: 3
                                            height: 3
                                            radius: 1.5
                                            color: {
                                                const ind = Planova.dayIndicator(panel.summaryFor(modelData.key))
                                                return ind.kind === "allDone" ? Theme.green : Theme.accent
                                            }
                                        }
                                    }
                                    Text {
                                        visible: {
                                            const ind = Planova.dayIndicator(panel.summaryFor(modelData.key))
                                            return ind.kind === "count"
                                        }
                                        text: {
                                            const ind = Planova.dayIndicator(panel.summaryFor(modelData.key))
                                            return ind.count > 0 ? String(ind.count) : ""
                                        }
                                        color: Theme.accent
                                        font { family: Theme.fontFamily; pixelSize: 8; bold: true }
                                    }
                                }
                            }
                            MouseArea { id: cellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: selectedKey = modelData.key }
                        }
                    }
                }
            }
        }

        // ── Selected day ──
        ColumnLayout {
            visible: !orgMissing
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "EVENTS"
                visible: (summary ? summary.events.length : 0) > 0
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 9; bold: true }
            }
            Repeater {
                model: summary ? summary.events : []
                delegate: Text {
                    required property var modelData
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: String(modelData.hour).padStart(2, "0") + ":" + String(modelData.minute).padStart(2, "0") + "  " + modelData.title
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 11 }
                }
            }
            Text {
                text: "TASKS"
                visible: (summary ? summary.tasks.length : 0) > 0
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 9; bold: true }
            }
            Repeater {
                model: summary ? summary.tasks : []
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: Theme.radiusSm
                    color: taskMa.containsMouse ? Theme.hover : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                        spacing: 8
                        Text {
                            text: modelData.done ? "[x]" : "[ ]"
                            color: modelData.done ? Theme.green : Theme.accent
                            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData.text
                            color: modelData.done ? Theme.dimText : Theme.text
                            font { family: Theme.fontFamily; pixelSize: 11; strikeout: modelData.done }
                        }
                    }
                    MouseArea { id: taskMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: toggleTask(modelData.lineIndex) }
                }
            }
            Text {
                visible: !summary || (summary.events.length === 0 && summary.tasks.length === 0)
                Layout.fillWidth: true
                text: summary ? "Nothing planned — add one below" : "No daily file yet — add one below"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 10 }
            }
        }

        // ── Quick add ──
        RowLayout {
            visible: !orgMissing
            Layout.fillWidth: true
            spacing: 6
            Rectangle {
                implicitWidth: 64
                implicitHeight: 30
                radius: Theme.radiusSm
                color: typeMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text {
                    anchors.centerIn: parent
                    text: addType === "todo" ? "Todo" : addType === "event" ? "Event" : "Log"
                    color: Theme.accent
                    font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                }
                MouseArea {
                    id: typeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: addType = addType === "todo" ? "event" : addType === "event" ? "log" : "todo"
                }
            }
            TextField {
                id: addField
                Layout.fillWidth: true
                placeholderText: addType === "todo" ? "New task" : addType === "event" ? "Event title" : "What happened?"
                font.family: Theme.fontFamily
                Keys.onReturnPressed: commitAdd(text, hourField.text, minField.text)
            }
            TextField {
                id: hourField
                visible: addType === "event"
                implicitWidth: 34
                placeholderText: "HH"
                maximumLength: 2
                validator: RegularExpressionValidator { regularExpression: /[0-9]{0,2}/ }
                font.family: Theme.fontFamily
                horizontalAlignment: Text.AlignHCenter
                Keys.onReturnPressed: commitAdd(addField.text, text, minField.text)
            }
            TextField {
                id: minField
                visible: addType === "event"
                implicitWidth: 34
                placeholderText: "MM"
                maximumLength: 2
                validator: RegularExpressionValidator { regularExpression: /[0-9]{0,2}/ }
                font.family: Theme.fontFamily
                horizontalAlignment: Text.AlignHCenter
                Keys.onReturnPressed: commitAdd(addField.text, hourField.text, text)
            }
            Rectangle {
                implicitWidth: 52
                implicitHeight: 30
                radius: Theme.radiusSm
                color: addMa.containsMouse ? Theme.hoverStrong : Theme.accent
                Text { anchors.centerIn: parent; text: "Add"; color: Theme.accentText; font { family: Theme.fontFamily; pixelSize: 10; bold: true } }
                MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: commitAdd(addField.text, hourField.text, minField.text) }
            }
        }

        // ── Refill: carry undone todos forward ──
        Rectangle {
            visible: !orgMissing && refillTodos.length > 0
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusSm
            color: refillMa.containsMouse ? Theme.hoverStrong : Theme.inactiveBg
            Text {
                anchors.centerIn: parent
                text: refillSel === "" ? ("Refill (" + refillTodos.length + " undone)") : "Refill selected (" + JSON.parse(refillSel || "[]").length + ")"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 10; bold: true }
            }
            MouseArea {
                id: refillMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (refillSel === "") refillSel = JSON.stringify(refillTodos.map(r => r.content))
                    else applyRefill()
                }
            }
        }
    }

    function summaryFor(key) {
        revision
        const c = dailies[key]
        return c !== undefined ? Planova.daySummary(key, c) : null
    }
}
