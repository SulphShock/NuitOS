import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Native keybinds cheatsheet — single source is ~/.config/nuit/keybinds.txt
// (same file Super+F1 used to page through less). Parsed into sections:
// non-indented short lines are headers, 2-space-indented lines are rows.
Rectangle {
    id: panel
    implicitWidth: 620
    implicitHeight: Math.min(600, contentCol.implicitHeight + 24)
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible

    onVisibleChanged: if (visible) { panelIn.restart(); keysFile.reload() }
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

    property var sections: []
    function parseCheatsheet(text) {
        const out = []
        let cur = null
        for (const raw of String(text).split("\n")) {
            if (raw.trim() === "" || /^=+$/.test(raw.trim())) continue
            if (/^  \S/.test(raw)) {
                const parts = raw.trim().split(/\s{2,}/)
                if (parts.length >= 2 && cur) cur.rows.push({ keys: parts[0], desc: parts.slice(1).join("  ") })
                else if (cur) cur.notes.push(raw.trim())
            } else {
                const title = raw.trim()
                // Short label-like lines are section headers; sentences
                // (footers, hints) attach to the current section as notes.
                if (title.length <= 28 && !/[=:]/.test(title) && !title.includes("http")) {
                    cur = { title: title, rows: [], notes: [] }
                    out.push(cur)
                } else if (cur) {
                    cur.notes.push(title)
                }
            }
        }
        return out
    }
    FileView {
        id: keysFile
        path: (Quickshell.env("HOME") || "/home/user") + "/.config/nuit/keybinds.txt"
        onLoaded: panel.sections = panel.parseCheatsheet(text())
    }

    component KeyPill: Rectangle {
        id: pill
        property string keys: ""
        implicitWidth: pillText.implicitWidth + 16
        implicitHeight: 22
        radius: 11
        color: Theme.inactiveBg
        border.color: Theme.outline
        border.width: 1
        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.keys
            color: Theme.accent
            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            WhiteIcon {
                size: 20
                source: Theme.icon("input-keyboard-symbolic")
                tint: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: "Keybinds"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 16; bold: true }
            }
            Text {
                text: "esc to close"
                color: Theme.dimText
                font { family: Theme.fontFamily; pixelSize: 11 }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(500, sectionCol.implicitHeight)
            contentHeight: sectionCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: sectionCol
                width: parent.width
                spacing: 12
                Repeater {
                    model: panel.sections
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: Theme.fgBright
                            font { family: Theme.fontFamily; pixelSize: 13; bold: true }
                        }
                        Repeater {
                            model: modelData.rows
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10
                                KeyPill { keys: modelData.keys }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    color: Theme.text
                                    wrapMode: Text.Wrap
                                    font { family: Theme.fontFamily; pixelSize: 12 }
                                }
                            }
                        }
                        Repeater {
                            model: modelData.notes
                            delegate: Text {
                                required property string modelData
                                Layout.fillWidth: true
                                text: modelData
                                color: Theme.dimText
                                wrapMode: Text.Wrap
                                font { family: Theme.fontFamily; pixelSize: 11 }
                            }
                        }
                    }
                }
            }
        }
    }
}
