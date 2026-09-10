import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import ".."

Rectangle {
    id: overlay
    color: Theme.scrim

    property int selectedIndex: 0

    // ── Entries hidden on request: avahi utils, xgps utils,
    // hardware locality (lstopo), Volume Control ──
    // NOTE: the Nuit OS Installer is intentionally VISIBLE (it is the disk
    // installer; README + keybinds sheet point users at the app grid).
    // Matched case-insensitively against the desktop id + display name.
    readonly property var hiddenMatchers: [
        "avahi",               // Avahi Zeroconf / SSH / VNC browsers
        "bssh", "bvnc",
        "xgps",                // xgps + xgpsspeed
        "v4l2", "qv4l2", "qvidcap", // Qt V4L2 test + video capture utilities
        "lstopo", "hardware locality",
        "pavucontrol", "volume control"
    ]

    function isHidden(entry) {
        const id = ((entry && entry.id) || "").toLowerCase()
        const nm = ((entry && entry.name) || "").toLowerCase()
        return hiddenMatchers.some(m => id.includes(m) || nm.includes(m))
    }

    // ── All launchable apps (pacman/yay + flatpak), sorted A–Z ──
    // DesktopEntries aggregates every XDG data dir:
    //   /usr/share/applications (pacman), ~/.local/share/applications (yay/AUR builds),
    //   /var/lib/flatpak/exports + ~/.local/share/flatpak/exports (flatpak).
    readonly property var allApps: DesktopEntries.applications.values
        .filter(a => a && !a.noDisplay && a.name && a.name !== "" && !isHidden(a))
        .slice()
        .sort((x, y) => x.name.localeCompare(y.name))

    readonly property var filteredApps: {
        const q = search.text.trim().toLowerCase()
        if (q === "")
            return allApps
        return allApps.filter(a =>
            a.name.toLowerCase().includes(q)
            || (a.genericName && a.genericName.toLowerCase().includes(q))
            || (a.comment && a.comment.toLowerCase().includes(q))
            || (a.keywords && a.keywords.some(k => k.toLowerCase().includes(q))))
    }

    onFilteredAppsChanged: {
        selectedIndex = 0
        if (appList.count > 0)
            appList.positionViewAtBeginning()
    }

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            selectedIndex = 0
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
        if (filteredApps.length > 0)
            launchEntry(filteredApps[Math.min(selectedIndex, filteredApps.length - 1)])
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

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 90
        }
        spacing: 20
        width: Math.min(640, overlay.width - 160)

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
            Keys.onUpPressed: {
                if (overlay.filteredApps.length > 0) {
                    overlay.selectedIndex = Math.max(0, overlay.selectedIndex - 1)
                    appList.positionViewAtIndex(overlay.selectedIndex, ListView.Contain)
                }
            }
            Keys.onDownPressed: {
                if (overlay.filteredApps.length > 0) {
                    overlay.selectedIndex = Math.min(overlay.filteredApps.length - 1, overlay.selectedIndex + 1)
                    appList.positionViewAtIndex(overlay.selectedIndex, ListView.Contain)
                }
            }
            Keys.onReturnPressed: overlay.launchSelected()
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: overlay.filteredApps.length + " application" + (overlay.filteredApps.length === 1 ? "" : "s")
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
            opacity: 0.8
        }

        // ── Scrollable vertical list: every app, logo + name ──
        Rectangle {
            width: parent.width
            height: Math.max(200, Math.min(480, overlay.height - 360))
            radius: Theme.radiusMd
            color: Theme.inactiveBg
            border.color: Theme.outline
            border.width: 1
            clip: true
            visible: overlay.filteredApps.length > 0

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 2
                model: overlay.filteredApps
                currentIndex: overlay.selectedIndex
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

                    readonly property bool isSelected: index === overlay.selectedIndex

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
                                source: overlay.appIconSource(row.modelData)
                                asynchronous: true
                            }
                            // Fallback glyph when the icon cannot load
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
                                text: overlay.appSubtitle(row.modelData)
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
                        onEntered: overlay.selectedIndex = index
                        onClicked: {
                            overlay.selectedIndex = index
                            overlay.launchEntry(row.modelData)
                        }
                    }
                }
            }
        }

        Text {
            visible: overlay.filteredApps.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: search.text === "" ? "No applications found" : "No applications match \"" + search.text + "\""
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 13 }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "↑ ↓ navigate  ·  ↵ launch  ·  Esc close"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 10 }
            opacity: 0.7
        }
    }
}
