// Capture board. Screenshots, clipboard tools, unit converter.
// See NOTICE.md for sources.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../lib/convert/index.js" as ConvertIndex
import "../lib/convert/preferences.js" as ConvertPreferences
import "../lib/convert/currency.js" as ConvertCurrency

Rectangle {
    id: board
    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.radiusLg
    color: Theme.background
    focus: visible
    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    property string clipText: ""
    property var convResult: null
    property bool copied: false
    property bool hasOcr: false
    property bool hasQr: false
    property var fxRates: null
    readonly property string fxFile: (Quickshell.env("HOME") || "/home/user") + "/.cache/nuit/fx.json"

    onVisibleChanged: {
        if (visible) {
            boardIn.restart()
            copied = false
            probe.running = true
            readClip.running = true
        }
    }
    NumberAnimation {
        id: boardIn
        target: board
        property: "opacity"
        from: 0
        to: 1
        duration: 150
        easing.type: Easing.OutCubic
    }

    // What can this machine actually do? OCR/QR buttons hide when their
    // binaries are missing instead of failing loudly on click.
    Process {
        id: probe
        command: ["sh", "-c", "mkdir -p \"$HOME/.cache/nuit\"; command -v tesseract >/dev/null && echo ocr; command -v zbarimg >/dev/null && echo qr"]
        stdout: StdioCollector {
            onStreamFinished: {
                board.hasOcr = text.indexOf("ocr") >= 0
                board.hasQr = text.indexOf("qr") >= 0
            }
        }
    }
    // Currency cache from the last fetch (or nothing on first run).
    FileView {
        id: fxLoad
        path: board.fxFile
        onLoaded: {
            try {
                const j = JSON.parse(text)
                if (j && j.rates) board.fxRates = { base: j.base || "USD", rates: j.rates, fetchedAt: j.fetchedAt || 0 }
            } catch (e) {}
        }
    }
    FileView {
        id: fxWrite
        atomicWrites: true
    }
    // Whatever's on the clipboard right now (capped, it's just a peek).
    Process {
        id: readClip
        command: ["sh", "-c", "wl-paste --no-newline 2>/dev/null | head -c 8192"]
        stdout: StdioCollector {
            onStreamFinished: {
                board.clipText = text || ""
                board.analyze()
            }
        }
    }
    function analyze() {
        copied = false
        if (clipText.trim() === "") { convResult = null; return }
        const prefs = ConvertPreferences.defaultPreferences(Qt.locale().name)
        convResult = ConvertIndex.analyze(clipText, prefs, { rates: fxRates, now: Date.now() })
        if (convResult && convResult.category && convResult.category.indexOf("currency") === 0
                && (!fxRates || ConvertCurrency.isStale(fxRates, Date.now()))) fetchFx()
    }
    function fetchFx() { fxProc.running = true }
    Process {
        id: fxProc
        command: ["curl", "-fsS", "--max-time", "6", "https://open.er-api.com/v6/latest/USD"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    if (j && j.rates) {
                        board.fxRates = { base: "USD", rates: j.rates, fetchedAt: Date.now() }
                        fxWrite.path = board.fxFile
                        fxWrite.setText(JSON.stringify(board.fxRates))
                        board.analyze()
                    }
                } catch (e) {}
            }
        }
    }
    Process {
        id: clipWrite
        stdinEnabled: true
        property string pending: ""
        command: ["wl-copy"]
        onStarted: write(pending + "\n")
        onExited: code => { if (code === 0) board.copied = true }
    }
    function copyResult(t) {
        copied = false
        clipWrite.pending = t
        clipWrite.running = true
    }
    // Captures need a clear screen: close everything first, then shoot.
    function shoot(args) {
        SysState.closeAll()
        SysState.runCmd(["nuit-screenshot"].concat(args))
    }

    // One chunky tool button. 5px, like everything new around here.
    component CapBtn: Rectangle {
        id: btn
        property string label
        property bool accent: false
        property bool btnEnabled: true
        signal fired()
        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.radiusMd
        opacity: btnEnabled ? 1 : 0.35
        color: btn.accent ? Theme.accent
            : btnMa.containsMouse ? Theme.hover : Theme.inactiveBg
        Text {
            anchors.centerIn: parent
            text: btn.label
            color: btn.accent ? Theme.accentText : Theme.text
            font { family: Theme.fontFamily; pixelSize: 11; bold: btn.accent }
        }
        MouseArea {
            id: btnMa
            anchors.fill: parent
            enabled: btn.btnEnabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.fired()
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Capture"
            color: Theme.text
            font { family: Theme.fontFamily; pixelSize: 15; bold: true }
        }

        CapBtn {
            label: "Capture region"
            accent: true
            onFired: board.shoot(["region", "both"])
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8
            CapBtn { label: "Window"; onFired: board.shoot(["window", "both"]) }
            CapBtn { label: "Fullscreen"; onFired: board.shoot(["fullscreen", "both"]) }
            CapBtn { label: "Save region to file"; onFired: board.shoot(["region", "save"]) }
            CapBtn {
                label: "Pick a color"
                onFired: {
                    SysState.closeAll()
                    SysState.runCmd(["sh", "-c", "pkill hyprpicker 2>/dev/null; hyprpicker -a"])
                }
            }
            CapBtn {
                label: "Clipboard history"
                onFired: SysState.launch("sh -c 'cliphist list | fuzzel --dmenu | cliphist decode | wl-copy'")
            }
            CapBtn {
                label: "Copy as plain text"
                onFired: SysState.runCmd(["sh", "-c", "wl-paste --no-newline 2>/dev/null | wl-copy && notify-send -a Nuit 'Clipboard simplified to plain text'"])
            }
            CapBtn {
                label: "Read text (OCR)"
                btnEnabled: board.hasOcr
                onFired: {
                    SysState.closeAll()
                    SysState.runCmd(["sh", "-c", "geo=$(slurp 2>/dev/null) || exit 0; [ -n \"$geo\" ] || exit 0; grim -g \"$geo\" - | tesseract stdin stdout 2>/dev/null | wl-copy && notify-send -a Nuit 'Text captured to clipboard'"])
                }
            }
            CapBtn {
                label: "Read QR code"
                btnEnabled: board.hasQr
                onFired: {
                    SysState.closeAll()
                    SysState.runCmd(["sh", "-c", "geo=$(slurp 2>/dev/null) || exit 0; [ -n \"$geo\" ] || exit 0; out=$(grim -g \"$geo\" - | zbarimg --raw --quiet - 2>/dev/null); if [ -n \"$out\" ]; then printf '%s' \"$out\" | wl-copy; notify-send -a Nuit 'QR captured to clipboard'; else notify-send -a Nuit 'No QR code found'; fi"])
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: !board.hasOcr || !board.hasQr
            wrapMode: Text.WordWrap
            text: "OCR needs tesseract, QR needs zbarimg — install what's missing and reopen."
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 10 }
        }

        // ── CONVERT: whatever's on the clipboard, already converted ──
        Rectangle {
            visible: board.convResult !== null
            Layout.fillWidth: true
            implicitHeight: convCol.implicitHeight + 16
            radius: Theme.radiusLg
            color: Theme.wellSoft
            ColumnLayout {
                id: convCol
                anchors { fill: parent; margins: 8 }
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: "CONVERT · " + (board.convResult ? board.convResult.source : "")
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 9; bold: true }
                }
                Repeater {
                    model: (board.convResult && board.convResult.ambiguous) ? board.convResult.options : []
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Theme.radiusSm
                        color: optMa.containsMouse ? Theme.hover : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            Text { Layout.fillWidth: true; text: modelData.label; color: Theme.dimText; elide: Text.ElideRight; font { family: Theme.fontFamily; pixelSize: 10 } }
                            Text { text: modelData.primary.text; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 11; bold: true } }
                        }
                        MouseArea { id: optMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: board.copyResult(modelData.primary.copyValue) }
                    }
                }
                Rectangle {
                    visible: !!(board.convResult && board.convResult.swatch)
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 20
                    radius: Theme.radiusSm
                    color: {
                        const s = board.convResult ? board.convResult.swatch : null
                        return s ? Qt.rgba(s.r / 255, s.g / 255, s.b / 255, 1) : "transparent"
                    }
                }
                Text {
                    visible: !!(board.convResult && !board.convResult.ambiguous && board.convResult.primary)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: (board.convResult && board.convResult.primary) ? board.convResult.primary.text : ""
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 15; bold: true }
                }
                Text {
                    visible: !!(board.convResult && board.convResult.note)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: (board.convResult && board.convResult.note) ? board.convResult.note : ""
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 10 }
                }
                Repeater {
                    model: (board.convResult && !board.convResult.ambiguous && board.convResult.alternatives) ? board.convResult.alternatives : []
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Theme.radiusSm
                        color: altMa.containsMouse ? Theme.hover : "transparent"
                        Text {
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            text: modelData.text
                            elide: Text.ElideRight
                            color: Theme.dimText
                            font { family: Theme.fontFamily; pixelSize: 10 }
                        }
                        MouseArea { id: altMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: board.copyResult(modelData.copyValue) }
                    }
                }
                Rectangle {
                    visible: !!(board.convResult && !board.convResult.ambiguous && board.convResult.primary)
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: Theme.radiusMd
                    color: copyMa.containsMouse ? Theme.hoverStrong : Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: board.copied ? "COPIED" : "COPY RESULT"
                        color: Theme.accentText
                        font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                    }
                    MouseArea { id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: board.copyResult(board.convResult.primary.copyValue) }
                }
            }
        }
    }
}
