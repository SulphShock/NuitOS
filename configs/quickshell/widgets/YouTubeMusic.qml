// Music player. Search, queue, mixes over mpv.
// See NOTICE.md for sources.
// Needs: yt-dlp, mpv, socat. Super+Ctrl+Shift+M not wired -- open it from the vinyl.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: panel
    implicitWidth: 400
    implicitHeight: 564
    radius: Theme.radiusLg
    color: Theme.background
    focus: visible
    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    property bool opened: false
    property bool searching: false
    property bool searchMode: false
    property bool searchExpanded: false
    property string errorMessage: ""
    property int selectedIndex: 0
    property int currentIndex: -1
    property string currentTitle: ""
    property string currentArtist: ""
    property string currentThumbnail: ""
    property string currentDuration: ""
    property string currentVideoId: ""
    property bool mixLoading: false
    property bool mixPrefetching: false
    property bool currentIsLive: false
    property bool playing: false
    property bool playerRunning: false
    property real position: 0
    property real playbackDuration: 0
    property var closeCallback: null
    readonly property string scriptPath: (Quickshell.env("HOME") || "/home/user") + "/.config/quickshell/lib/ytmusic.sh"

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            open()
        } else close()
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

    function open() {
        opened = true
        errorMessage = ""
        searchExpanded = searchMode || searchField.text.trim() !== "" || currentTitle === ""
        refreshStatus()
        if (searchExpanded) expandSearch()
    }
    function close() {
        searchField.focus = false
        searchExpanded = false
        opened = false
    }
    function requestClose() {
        if (closeCallback) closeCallback()
        else close()
    }

    function formatTime(seconds) {
        var value = Math.max(0, Math.floor(Number(seconds) || 0))
        var hours = Math.floor(value / 3600)
        var minutes = Math.floor((value % 3600) / 60)
        var remainingSeconds = value % 60
        if (hours > 0)
            return hours + ":" + String(minutes).padStart(2, "0") + ":" + String(remainingSeconds).padStart(2, "0")
        return minutes + ":" + String(remainingSeconds).padStart(2, "0")
    }
    function isVideoId(value) {
        return /^[A-Za-z0-9_-]{11}$/.test(String(value || ""))
    }
    function durationLabel(duration, isLive) {
        var value = String(duration || "").trim()
        if (isLive || value.toUpperCase() === "NA" || value.toUpperCase() === "N/A") return "LIVE"
        return value || "--:--"
    }
    function expandSearch() {
        searchExpanded = true
        Qt.callLater(function() {
            searchField.forceActiveFocus()
            focusTimer.restart()
        })
    }
    function collapseSearch() {
        searchField.focus = false
        searchExpanded = false
        panel.forceActiveFocus()
        Qt.callLater(function() { panel.forceActiveFocus() })
    }
    function toggleSearch() {
        if (!opened) return false
        if (searchExpanded) collapseSearch()
        else expandSearch()
        return true
    }
    function search() {
        var query = searchField.text.trim()
        if (!query) return
        if (searchProc.running) {
            searchProc.pendingQuery = query
            return
        }
        startSearch(query)
    }
    function startSearch(query) {
        searchDebounce.stop()
        searchProc.activeQuery = query
        searchProc.pendingQuery = ""
        searchMode = true
        searching = true
        errorMessage = ""
        results.clear()
        selectedIndex = 0
        searchProc.command = ["bash", scriptPath, "search", query]
        searchProc.running = true
    }
    // `mix` returns exactly the same TSV as `search`, so search, the mix
    // button and the automatic mix all share this parser.
    function parseTracks(raw, limit) {
        var out = []
        var lines = String(raw || "").trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue
            var fields = lines[i].split("\t")
            if (fields.length < 2) continue
            var videoId = fields[0]
            if (!isVideoId(videoId)) continue
            var duration = fields[3] || ""
            out.push({
                videoId: videoId,
                title: fields[1] || "Untitled",
                artist: fields[2] || "YouTube",
                duration: duration,
                isLive: fields[5] === "is_live" || duration.toUpperCase() === "NA",
                thumbnail: (!fields[4] || fields[4] === "NA")
                    ? "https://i.ytimg.com/vi/" + videoId + "/hqdefault.jpg"
                    : fields[4]
            })
            if (out.length >= limit) break
        }
        return out
    }
    function fillResults(raw, limit) {
        var tracks = parseTracks(raw, limit)
        for (var i = 0; i < tracks.length; i++) results.append(tracks[i])
    }
    // A mix starts playing right away: YouTube returns the seed first, so
    // playAt(0) keeps what's on air and queues the rest behind it.
    function startMix(videoId) {
        if (!isVideoId(videoId)) return
        for (var i = 0; i < results.count; i++) {
            if (results.get(i).videoId !== videoId) continue
            playAt(i)
            prefetchMix(videoId)
            return
        }
        if (currentVideoId === videoId) {
            searchMode = false
            collapseSearch()
            prefetchMix(videoId)
        }
    }
    // Picking a SEARCH result builds its mix (that's what YouTube Music does
    // when you open a song). Picking inside "up next" only jumps there.
    function selectTrack(index) {
        if (index < 0 || index >= results.count) return
        var fromSearch = searchMode
        var videoId = results.get(index).videoId
        collapseSearch()
        selectedIndex = index
        playAt(index)
        if (fromSearch) prefetchMix(videoId)
    }
    // The chosen track keeps playing while yt-dlp resolves the mix; only the
    // queue gets swapped when it lands.
    function prefetchMix(videoId) {
        if (!isVideoId(videoId) || mixLoading) return
        if (mixProc.running) { mixProc.pending = videoId; return }
        mixProc.pending = ""
        mixProc.seed = videoId
        mixPrefetching = true
        mixProc.command = ["bash", scriptPath, "mix", videoId]
        mixProc.running = true
    }
    // Swaps the queue for the mix while the track on air keeps playing.
    function applyMix(raw, seed) {
        var mix = parseTracks(raw, 40)
        if (mix.length === 0) return
        var seedAt = -1
        for (var i = 0; i < mix.length; i++) {
            if (mix[i].videoId === seed) { seedAt = i; break }
        }
        if (seedAt < 0) {
            mix.unshift({
                videoId: seed,
                title: currentTitle,
                artist: currentArtist,
                duration: currentDuration,
                isLive: currentIsLive,
                thumbnail: currentThumbnail
            })
            seedAt = 0
        }
        results.clear()
        for (var j = 0; j < mix.length; j++) results.append(mix[j])
        currentIndex = seedAt
        selectedIndex = seedAt
        // `requeue`, not `queue`: relaunching mpv would cut the audio.
        requeueProc.command = ["bash", scriptPath, "requeue", queueJson(), String(seedAt), seed]
        requeueProc.running = true
    }
    function queueJson() {
        var queue = []
        for (var i = 0; i < results.count; i++) {
            var row = results.get(i)
            queue.push({
                videoId: row.videoId,
                title: row.title,
                artist: row.artist,
                thumbnail: row.thumbnail,
                duration: row.duration,
                isLive: row.isLive
            })
        }
        return JSON.stringify(queue)
    }
    function playAt(index) {
        if (index < 0 || index >= results.count) return
        var track = results.get(index)
        currentIndex = index
        currentTitle = track.title
        currentArtist = track.artist
        currentThumbnail = track.thumbnail
        currentDuration = track.duration
        currentVideoId = track.videoId
        currentIsLive = track.isLive === true
        position = 0
        playbackDuration = 0
        playing = true
        playerRunning = true
        searchDebounce.stop()
        searchMode = false
        collapseSearch()
        var command = ["bash", scriptPath, "queue", queueJson(), String(index)]
        if (actionProc.running) actionProc.pendingCommand = command
        else { actionProc.command = command; actionProc.running = true }
    }
    function runAction(action) {
        if (actionProc.running) return
        actionProc.command = ["bash", scriptPath, action]
        actionProc.running = true
    }
    function next() { runAction("next") }
    function previous() { runAction("previous") }
    function togglePlayback() {
        if (!playerRunning && results.count > 0) {
            playAt(Math.max(0, selectedIndex))
            return
        }
        runAction("toggle")
        playing = !playing
    }
    function refreshStatus() {
        if (statusProc.running) return
        statusProc.command = ["bash", scriptPath, "status"]
        statusProc.running = true
    }
    function applyStatus(raw) {
        try {
            var status = JSON.parse(String(raw || "{}"))
            playerRunning = status.running === true
            playing = playerRunning && status.paused !== true
            position = Number(status.position) || 0
            playbackDuration = Number(status.playbackDuration) || 0
            if (status.title) currentTitle = String(status.title)
            if (status.artist) currentArtist = String(status.artist)
            if (status.thumbnail) currentThumbnail = String(status.thumbnail)
            if (status.duration) currentDuration = String(status.duration)
            if (status.videoId) currentVideoId = String(status.videoId)
            if (status.isLive !== undefined) currentIsLive = status.isLive === true
            else if (String(status.duration || "").toUpperCase() === "NA") currentIsLive = true
            if (status.index !== undefined) currentIndex = Number(status.index)
            if (status.queue && status.queue.length > 0 && results.count === 0 && !searching && !searchMode) {
                for (var i = 0; i < status.queue.length; i++) {
                    var row = status.queue[i]
                    var videoId = String(row.videoId || "")
                    if (!panel.isVideoId(videoId)) continue
                    var duration = String(row.duration || "")
                    results.append({
                        videoId: videoId,
                        title: String(row.title || "Untitled"),
                        artist: String(row.artist || "YouTube"),
                        duration: duration,
                        isLive: row.isLive === true || duration.toUpperCase() === "NA",
                        thumbnail: String(row.thumbnail || "")
                    })
                }
            }
        } catch (error) {
            console.warn("YouTube Music: invalid player status", error)
        }
    }

    ListModel { id: results }

    Process {
        id: searchProc
        property string collected: ""
        property string activeQuery: ""
        property string pendingQuery: ""
        property string mode: "search"
        stdout: SplitParser { onRead: function(line) { searchProc.collected += line + "\n" } }
        stderr: StdioCollector { id: searchError; waitForEnd: true }
        onStarted: collected = ""
        onExited: function(code) {
            if (mode === "mix") {
                mode = "search"
                searching = false
                mixLoading = false
                panel.fillResults(collected, 40)
                if (results.count > 0) panel.playAt(0)
                else errorMessage = searchError.text.trim() || "No mix for this track"
                return
            }
            if (!panel.searchMode) { searching = false; return }
            var currentQuery = searchField.text.trim()
            if (pendingQuery && pendingQuery !== activeQuery) {
                panel.startSearch(pendingQuery)
                return
            }
            if (!currentQuery || currentQuery !== activeQuery) {
                searching = false
                searchMode = currentQuery !== ""
                results.clear()
                if (currentQuery) panel.startSearch(currentQuery)
                else panel.refreshStatus()
                return
            }
            searching = false
            panel.fillResults(collected, 10)
            if (code !== 0) errorMessage = searchError.text.trim() || "Search failed"
            else if (results.count === 0) errorMessage = "No tracks found"
            else if (!playerRunning) resultList.forceActiveFocus()
        }
    }
    Process {
        id: actionProc
        property var pendingCommand: null
        onExited: {
            if (pendingCommand) {
                command = pendingCommand
                pendingCommand = null
                running = true
            } else refreshStatus()
        }
    }
    Process {
        id: mixProc
        property string collected: ""
        property string seed: ""
        property string pending: ""
        stdout: SplitParser { onRead: function(line) { mixProc.collected += line + "\n" } }
        onStarted: collected = ""
        onExited: function(code) {
            panel.mixPrefetching = false
            var pendingSeed = pending
            pending = ""
            if (pendingSeed && pendingSeed !== seed) { panel.prefetchMix(pendingSeed); return }
            if (code !== 0 || panel.searchMode || panel.searching || panel.currentVideoId !== seed) return
            panel.applyMix(collected, seed)
        }
    }
    Process {
        id: requeueProc
        onExited: refreshStatus()
    }
    Process {
        id: statusProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyStatus(text)
        }
    }
    Timer {
        interval: 900
        running: panel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: panel.refreshStatus()
    }
    Timer {
        id: focusTimer
        interval: 90
        repeat: false
        onTriggered: searchField.forceActiveFocus()
    }
    Timer {
        id: searchDebounce
        interval: 550
        repeat: false
        onTriggered: panel.search()
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: "YouTube Music"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 13; bold: true }
            }
            Rectangle {
                id: searchBox
                Layout.preferredWidth: panel.searchExpanded ? Math.min(252, contentCol.width - 130) : 32
                Layout.preferredHeight: 30
                radius: 15
                color: panel.searchExpanded ? Theme.inactiveBg : "transparent"
                border.width: panel.searchExpanded && searchField.activeFocus ? 1 : 0
                border.color: Theme.text
                clip: true
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 145; easing.type: Easing.OutExpo } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    spacing: 2
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        font { family: Theme.fontFamily; pixelSize: 11 }
                        clip: true
                        enabled: panel.searchExpanded
                        opacity: panel.searchExpanded ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        onTextChanged: {
                            var query = text.trim()
                            if (!panel.opened) return
                            if (!query) {
                                searchDebounce.stop()
                                searchProc.pendingQuery = ""
                                panel.searchMode = false
                                panel.errorMessage = ""
                                if (!searchProc.running) {
                                    results.clear()
                                    panel.refreshStatus()
                                }
                            } else if (query.length >= 2) {
                                searchDebounce.restart()
                            }
                        }
                        Text {
                            text: "Search music…"
                            color: Theme.dimText
                            font: searchField.font
                            visible: panel.searchExpanded && !searchField.text
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) { panel.requestClose(); event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { searchDebounce.stop(); panel.search(); event.accepted = true }
                            else if (event.key === Qt.Key_Down && results.count > 0) { panel.selectedIndex = Math.min(results.count - 1, panel.selectedIndex + 1); resultList.forceActiveFocus(); event.accepted = true }
                        }
                    }
                    Text {
                        text: "\uf002"
                        color: panel.searchExpanded ? Theme.text : Theme.dimText
                        font { family: Theme.fontFamily; pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!panel.searchExpanded) panel.expandSearch()
                                else {
                                    searchField.forceActiveFocus()
                                    if (searchField.text.trim()) panel.search()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Now playing ──
        ColumnLayout {
            visible: panel.currentTitle !== "" && !panel.searchMode
            Layout.fillWidth: true
            spacing: 6
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 180
                implicitHeight: 180
                radius: Theme.radiusMd
                color: Theme.inactiveBg
                clip: true
                Image {
                    anchors.fill: parent
                    source: panel.currentThumbnail
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 360
                    sourceSize.height: 360
                    visible: source !== "" && status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: panel.currentThumbnail === ""
                    text: "\uf001"
                    color: Theme.dimText
                    font.pixelSize: 40
                }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: panel.currentTitle
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 14; bold: true }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: panel.currentArtist
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 11 }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Text {
                    Layout.preferredWidth: 44
                    text: panel.formatTime(panel.position)
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 10 }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 3
                    radius: 2
                    color: Theme.wellSoft
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * Math.min(1, panel.position / Math.max(1, panel.playbackDuration))
                        radius: 2
                        color: Theme.accent
                    }
                }
                Text {
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                    text: panel.playbackDuration > 0 ? panel.formatTime(panel.playbackDuration) : panel.durationLabel(panel.currentDuration, panel.currentIsLive)
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 10 }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                Text {
                    text: "\uf048"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.collapseSearch(); panel.previous() } }
                }
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 22
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: panel.playing ? "\uf04c" : "\uf04b"
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 16 }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.collapseSearch(); panel.togglePlayback() } }
                }
                Text {
                    text: "\uf051"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { panel.collapseSearch(); panel.next() } }
                }
                Text {
                    text: "\uf074"
                    visible: panel.isVideoId(panel.currentVideoId)
                    color: panel.mixLoading ? Theme.accent : Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 16 }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.startMix(panel.currentVideoId) }
                }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: panel.mixLoading || panel.mixPrefetching
                text: "Building mix…"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 10 }
            }
            Text {
                Layout.fillWidth: true
                text: "Up next"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 11; bold: true }
            }
            ListView {
                id: upNextList
                Layout.fillWidth: true
                Layout.preferredHeight: 148
                model: results
                clip: true
                spacing: 2
                currentIndex: panel.currentIndex
                onCurrentIndexChanged: if (currentIndex >= 0 && currentIndex < count) positionViewAtIndex(currentIndex, ListView.Contain)
                delegate: TrackRow {}
            }
        }

        // ── Search results / empty state ──
        ColumnLayout {
            visible: panel.currentTitle === "" || panel.searchMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: panel.searching || (results.count === 0 && panel.errorMessage === "")
                text: panel.searching ? "Searching YouTube…" : "Search for something worth hearing"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 12 }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: panel.errorMessage !== ""
                text: panel.errorMessage
                color: Theme.error
                font { family: Theme.fontFamily; pixelSize: 12 }
            }
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 300
                model: results
                clip: true
                spacing: 3
                visible: results.count > 0
                currentIndex: panel.selectedIndex
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) { panel.requestClose(); event.accepted = true }
                    else if (event.key === Qt.Key_Up) { if (panel.selectedIndex === 0) searchField.forceActiveFocus(); else panel.selectedIndex--; event.accepted = true }
                    else if (event.key === Qt.Key_Down) { panel.selectedIndex = Math.min(results.count - 1, panel.selectedIndex + 1); event.accepted = true }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { panel.selectTrack(panel.selectedIndex); event.accepted = true }
                }
                delegate: TrackRow { expanded: true }
            }
        }
    }

    component TrackRow: Rectangle {
        id: trackRow
        required property int index
        required property string title
        required property string artist
        required property string duration
        required property bool isLive
        required property string thumbnail
        required property string videoId
        property bool expanded: false
        width: ListView.view ? ListView.view.width : 0
        implicitHeight: expanded ? 50 : 38
        opacity: (!expanded && panel.currentIndex >= 0 && index < panel.currentIndex) ? 0.45 : 1
        Behavior on opacity { NumberAnimation { duration: 140 } }
        radius: Theme.radiusSm
        color: index === panel.selectedIndex ? Theme.inactiveBg : (trackArea.containsMouse || rowMixArea.containsMouse ? Theme.hover : "transparent")
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 6
            spacing: 7
            Rectangle {
                Layout.preferredWidth: expanded ? 40 : 30
                Layout.preferredHeight: expanded ? 40 : 30
                radius: Theme.radiusSm
                color: Theme.inactiveBg
                clip: true
                Layout.alignment: Qt.AlignVCenter
                Image { anchors.fill: parent; source: trackRow.thumbnail; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Text { Layout.fillWidth: true; text: trackRow.title; color: trackRow.index === panel.currentIndex ? Theme.accent : Theme.text; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 11; bold: trackRow.index === panel.currentIndex } }
                Text { Layout.fillWidth: true; text: trackRow.artist; color: Theme.dimText; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 10 } }
            }
            Text {
                text: "\uf074"
                color: rowMixArea.containsMouse ? Theme.accent : Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 13 }
                opacity: (trackArea.containsMouse || rowMixArea.containsMouse) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 90 } }
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    id: rowMixArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.startMix(trackRow.videoId)
                }
            }
            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: panel.durationLabel(trackRow.duration, trackRow.isLive)
                color: trackRow.isLive ? Theme.accent : Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 10 }
                Layout.alignment: Qt.AlignVCenter
            }
        }
        MouseArea {
            id: trackArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.selectTrack(trackRow.index)
        }
    }
}
