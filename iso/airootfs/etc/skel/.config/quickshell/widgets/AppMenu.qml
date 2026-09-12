// App launcher. Fuzzy search, icon grid, calculator, web search.
// See NOTICE.md for sources.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import "../lib/FuzzySearch.js" as Fuzzy

Rectangle {
    id: menu
    color: Theme.scrim
    focus: visible

    // Launcher-wide keys: hold even when the search box lost focus.
    Keys.onEscapePressed: SysState.actOpen = false
    Keys.onUpPressed: moveSelection(0, -1)
    Keys.onDownPressed: moveSelection(0, 1)
    Keys.onLeftPressed: { if (gridVisible) moveSelection(-1, 0) }
    Keys.onRightPressed: { if (gridVisible) moveSelection(1, 0) }
    Keys.onTabPressed: function(event) { gridView = !gridView; event.accepted = true }

    property int selectedIndex: 0
    property bool gridView: true
    property int gridCols: 5

    // Entries hidden on request: none right now. Owner will say what to
    // hide later; until then everything installed is shown.
    // Matched case-insensitively against the desktop id + display name.
    readonly property var hiddenMatchers: [
    ]

    function isHidden(entry) {
        const id = ((entry && entry.id) || "").toLowerCase()
        const nm = ((entry && entry.name) || "").toLowerCase()
        return hiddenMatchers.some(m => id.includes(m) || nm.includes(m))
    }

    // ── All launchable apps, sorted A–Z until you type ──
    // appRev forces a recompute: new installs change DesktopEntries while
    // the shell runs, but the .values array never notifies on its own.
    property int appRev: 0
    readonly property var allApps: {
        appRev                // bumped on open + whenever the entry count changes
        return DesktopEntries.applications.values
            .filter(a => a && !a.noDisplay && a.name && a.name !== "" && !isHidden(a))
            .slice()
            .sort((x, y) => x.name.localeCompare(y.name))
    }
    Connections {
        target: DesktopEntries.applications
        function onCountChanged() { menu.appRev++ }
    }

    function bookmarkFor(a) {
        return {
            title: a.name || "",
            domain: [a.genericName, a.comment].filter(x => x).join(" "),
            tags: a.keywords || [],
            link: a.id || "",
            entry: a
        }
    }
    readonly property var filteredApps: {
        const q = search.text.trim()
        if (q === "")
            return allApps
        return Fuzzy.search(q, allApps.map(bookmarkFor)).map(b => b.entry)
    }
    // Same grammar as better-menu: numbers, +-*/%^ and parens, needs an
    // operator, evaluated by a tiny parser below. Never eval().
    readonly property var calcResult: {
        const q = search.text.trim()
        return calcEvaluate(q)
    }
    function calcEvaluate(query) {
        var expr = String(query || "").trim()
        if (!/^[0-9\s+\-*/%^().]+$/.test(expr)) return null
        if (!/[0-9]/.test(expr)) return null
        if (!/[+\-*/%^]/.test(expr.replace(/^\s*-/, ""))) return null
        var tokens = []
        var re = /\s*([0-9]*\.?[0-9]+|[+\-*/%^()])\s*/g
        var m, last = 0
        while ((m = re.exec(expr)) !== null) {
            if (m.index !== last) return null
            last = m.index + m[0].length
            tokens.push(m[1])
        }
        if (last !== expr.length || tokens.length === 0) return null
        var pos = 0
        function peek() { return pos < tokens.length ? tokens[pos] : null }
        function parsePrimary() {
            var t = tokens[pos++]
            if (t === undefined) throw 0
            if (/^[0-9]/.test(t)) return parseFloat(t)
            if (t === "(") {
                var v = parseExpr()
                if (tokens[pos++] !== ")") throw 0
                return v
            }
            throw 0
        }
        function parseUnary() {
            var t = peek()
            if (t === "-" || t === "+") { pos++; var v = parseUnary(); return t === "-" ? -v : v }
            return parsePrimary()
        }
        function parseFactor() {
            var base = parseUnary()
            if (peek() === "^") { pos++; return Math.pow(base, parseFactor()) }
            return base
        }
        function parseTerm() {
            var v = parseFactor()
            for (;;) {
                var t = peek()
                if (t === "*") { pos++; v *= parseFactor() }
                else if (t === "/") { pos++; v /= parseFactor() }
                else if (t === "%") { pos++; v %= parseFactor() }
                else break
            }
            return v
        }
        function parseExpr() {
            var v = parseTerm()
            for (;;) {
                var t = peek()
                if (t === "+") { pos++; v += parseTerm() }
                else if (t === "-") { pos++; v -= parseTerm() }
                else break
            }
            return v
        }
        try {
            var result = parseExpr()
            if (pos !== tokens.length) return null
            if (typeof result !== "number" || !isFinite(result)) return null
            return Math.round(result * 1e10) / 1e10
        } catch (e) { return null }
    }

    onFilteredAppsChanged: {
        selectedIndex = 0
        if (appList.count > 0)
            appList.positionViewAtBeginning()
        if (appGrid.count > 0)
            appGrid.positionViewAtBeginning()
    }

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            selectedIndex = 0
            menu.appRev++   // fresh installs appear without a shell restart
            search.forceActiveFocus()
        }
    }

    function launchEntry(entry) {
        if (!entry)
            return
        entry.execute()
        SysState.actOpen = false
    }
    function launchSelected() {
        if (calcResult !== null && search.text.trim() !== "") {
            SysState.runCmd(["wl-copy", String(calcResult)])
            SysState.actOpen = false
            return
        }
        if (filteredApps.length > 0)
            launchEntry(filteredApps[Math.min(selectedIndex, filteredApps.length - 1)])
    }
    function openWebSearch() {
        const q = search.text.trim()
        if (q === "") return
        SysState.launch("xdg-open 'https://duckduckgo.com/?q=" + encodeURIComponent(q) + "'")
    }
    function moveSelection(dx, dy) {
        if (filteredApps.length === 0) return
        const cols = gridView && gridVisible ? gridCols : 1
        selectedIndex = Math.min(filteredApps.length - 1, Math.max(0, selectedIndex + dx + dy * cols))
        const view = gridView && gridVisible ? appGrid : appList
        view.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    // Themed name or absolute path -> loadable image source, "" if none.
    function appIconSource(entry) {
        if (!entry || !entry.icon)
            return Quickshell.iconPath("application-x-executable", true)
        const p = Quickshell.iconPath(entry.icon, true)
        if (p !== "")
            return p
        if (entry.icon.startsWith("/"))
            return entry.icon
        return Quickshell.iconPath("application-x-executable", true)
    }

    function appSubtitle(entry) {
        if (entry.genericName && entry.genericName !== "" && entry.genericName !== entry.name)
            return entry.genericName
        if (entry.comment && entry.comment !== "")
            return entry.comment
        return ""
    }

    MouseArea { anchors.fill: parent; onClicked: SysState.actOpen = false }

    property bool gridVisible: gridView && filteredApps.length > 0
    property bool listVisible: !gridView && filteredApps.length > 0

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 90
        }
        spacing: 16
        width: Math.min(640, menu.width - 160)

        RowLayout {
            width: parent.width
            spacing: 12
            Row {
                spacing: 12
                Image {
                    width: 42
                    height: 42
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("../assets/Logo.png")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    scale: logoMa.containsMouse ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    MouseArea { id: logoMa; anchors.fill: parent; hoverEnabled: true }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Applications"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 18; bold: true }
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 76
                implicitHeight: 26
                radius: Theme.radiusSm
                color: viewMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text {
                    anchors.centerIn: parent
                    text: gridView ? "Grid" : "List"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                }
                MouseArea { id: viewMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gridView = !gridView }
            }
        }

        TextField {
            id: search
            width: Math.min(560, parent.width)
            height: 46
            anchors.horizontalCenter: parent.horizontalCenter
            font { family: Theme.fontFamily; pixelSize: 14 }
            color: Theme.text
            placeholderText: "Type to search — or math, like 2*(3+4)^2"
            placeholderTextColor: Theme.faintText
            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 18; rightPadding: 18
            background: Rectangle {
                radius: height / 2
                color: Theme.wellSoft
                border.color: search.activeFocus ? Theme.focusBorder : Theme.outline
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 140 } }
            }
            Keys.onEscapePressed: SysState.actOpen = false
            Keys.onPressed: function(event) {
                const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
                if (event.key === Qt.Key_Down) { menu.moveSelection(0, 1); event.accepted = true }
                else if (event.key === Qt.Key_Up) { menu.moveSelection(0, -1); event.accepted = true }
                else if (event.key === Qt.Key_Left) { if (menu.gridVisible) menu.moveSelection(-1, 0); event.accepted = true }
                else if (event.key === Qt.Key_Right) { if (menu.gridVisible) menu.moveSelection(1, 0); event.accepted = true }
                else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { menu.gridView = !menu.gridView; event.accepted = true }
                else if ((event.key === Qt.Key_J && ctrl)) { menu.moveSelection(0, 1); event.accepted = true }
                else if ((event.key === Qt.Key_K && ctrl)) { menu.moveSelection(0, -1); event.accepted = true }
                else if ((event.key === Qt.Key_N && ctrl)) { menu.moveSelection(0, 1); event.accepted = true }
                else if ((event.key === Qt.Key_P && ctrl)) { menu.moveSelection(0, -1); event.accepted = true }
                else if ((event.key === Qt.Key_H && ctrl)) { menu.moveSelection(-1, 0); event.accepted = true }
                else if ((event.key === Qt.Key_L && ctrl)) { menu.moveSelection(1, 0); event.accepted = true }
                else if (event.key === Qt.Key_PageUp) { menu.moveSelection(0, -3); event.accepted = true }
                else if (event.key === Qt.Key_PageDown) { menu.moveSelection(0, 3); event.accepted = true }
                else if (event.key === Qt.Key_Home) { menu.selectedIndex = 0; event.accepted = true }
                else if (event.key === Qt.Key_End) { menu.selectedIndex = menu.filteredApps.length - 1; event.accepted = true }
            }
            Keys.onReturnPressed: {
                if (menu.calcResult !== null && search.text.trim() !== "") menu.launchSelected()
                else if (menu.filteredApps.length > 0) menu.launchSelected()
                else menu.openWebSearch()
            }
        }

        // Calculator answer. Enter copies it.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(560, parent.width)
            implicitHeight: 40
            radius: Theme.radiusMd
            visible: calcResult !== null && search.text.trim() !== ""
            color: Theme.inactiveBg
            border.color: Theme.accent
            border.width: 1
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                Text { text: "= " + calcResult; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 15; bold: true } }
                Item { Layout.fillWidth: true }
                Text { text: "↵ copies"; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 10 } }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: menu.launchSelected() }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: menu.filteredApps.length + " application" + (menu.filteredApps.length === 1 ? "" : "s")
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
            opacity: 0.8
        }

        // ── Grid: icon tiles, arrows move a full row ──
        GridView {
            id: appGrid
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: Math.max(200, Math.min(420, menu.height - 420))
            visible: menu.gridVisible
            clip: true
            cellWidth: 118
            cellHeight: 104
            model: menu.filteredApps
            currentIndex: menu.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: 118
                height: 104
                readonly property bool isSelected: index === menu.selectedIndex
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Theme.radiusMd
                    color: cellMa.containsMouse || cell.isSelected ? Theme.hover : "transparent"
                    border.color: cell.isSelected ? Theme.accent : "transparent"
                    border.width: cell.isSelected ? 1 : 0
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        width: parent.width - 12
                        Item {
                            width: 40
                            height: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            IconImage {
                                id: gridIcon
                                anchors.fill: parent
                                source: menu.appIconSource(cell.modelData)
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: gridIcon.status === Image.Error || gridIcon.source === ""
                                text: (cell.modelData.name || "?").charAt(0).toUpperCase()
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: 18; bold: true }
                            }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            text: cell.modelData.name
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 10; bold: cell.isSelected }
                        }
                    }
                }
                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: menu.selectedIndex = index
                    onClicked: {
                        menu.selectedIndex = index
                        menu.launchEntry(cell.modelData)
                    }
                }
            }
        }

        // ── List: the familiar rows ──
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: Math.max(200, Math.min(420, menu.height - 420))
            radius: Theme.radiusMd
            color: Theme.inactiveBg
            border.color: Theme.outline
            border.width: 1
            clip: true
            visible: menu.listVisible

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 2
                model: menu.filteredApps
                currentIndex: menu.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.focusBorder
                    }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: appList.width - (appList.ScrollBar.vertical.visible ? appList.ScrollBar.vertical.width + 4 : 0)
                    height: 56

                    readonly property bool isSelected: index === menu.selectedIndex

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        color: rowMa.containsMouse || row.isSelected ? Theme.hover : "transparent"
                        border.color: row.isSelected ? Theme.accent : "transparent"
                        border.width: row.isSelected ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 12

                        Item {
                            width: 40
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                source: menu.appIconSource(row.modelData)
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status === Image.Error || appIcon.source === ""
                                text: (row.modelData.name || "?").charAt(0).toUpperCase()
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: 18; bold: true }
                            }
                        }

                        Column {
                            width: parent.width - 52
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: row.modelData.name
                                color: Theme.text
                                font { family: Theme.fontFamily; pixelSize: 13; bold: row.isSelected }
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                elide: Text.ElideRight
                                text: menu.appSubtitle(row.modelData)
                                color: Theme.dimText
                                font { family: Theme.fontFamily; pixelSize: 11 }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: menu.selectedIndex = index
                        onClicked: {
                            menu.selectedIndex = index
                            menu.launchEntry(row.modelData)
                        }
                    }
                }
            }
        }

        Text {
            visible: menu.filteredApps.length === 0 && calcResult === null
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: search.text === "" ? "No applications found" : "No applications match \"" + search.text + "\""
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 13 }
        }

        // Web search sits at the bottom, only for real queries.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(560, parent.width)
            implicitHeight: 38
            radius: Theme.radiusMd
            visible: search.text.trim() !== ""
            color: webMa.containsMouse ? Theme.hover : Theme.inactiveBg
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                Text { text: "\uf002"; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 12 } }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: "Search DuckDuckGo for \"" + search.text.trim() + "\""
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 12 }
                }
            }
            MouseArea { id: webMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: menu.openWebSearch() }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "↑ ↓ ← → navigate  ·  ↵ launch  ·  Esc close"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 10 }
            opacity: 0.7
        }
    }
}
