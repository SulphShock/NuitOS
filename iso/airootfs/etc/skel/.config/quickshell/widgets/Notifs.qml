// Notifs -- everything the desktop tried to tell you while you were busy.
// Newest first, tap × to dismiss one, Clear all for the scorched-earth
// option. DND only quiets the bell badge; the list misses nothing.
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: panel
    implicitWidth: 360
    implicitHeight: Math.min(480, contentCol.implicitHeight + 24)
    radius: Theme.radiusLg
    color: Theme.menuBg
    focus: visible
    MouseArea { anchors.fill: parent }   // swallow clicks (scrim must not close us)

    onVisibleChanged: {
        if (visible) {
            panelIn.restart()
            SysState.notifRead = SysState.notifications.length
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

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 15; bold: true }
            }
            Rectangle {
                implicitWidth: 62
                implicitHeight: 26
                radius: Theme.radiusSm
                color: SysState.dnd ? Theme.accent : (dndMa.containsMouse ? Theme.hover : Theme.inactiveBg)
                Text {
                    anchors.centerIn: parent
                    text: "DND"
                    color: SysState.dnd ? Theme.accentText : Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 10; bold: true }
                }
                MouseArea { id: dndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.dnd = !SysState.dnd }
            }
            Rectangle {
                implicitWidth: 72
                implicitHeight: 26
                radius: Theme.radiusSm
                visible: SysState.notifications.length > 0
                color: clrMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 10 }
                }
                MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.clearNotifications() }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(360, contentHeight)
            visible: SysState.notifications.length > 0
            clip: true
            spacing: 4
            model: SysState.notifications
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                implicitHeight: Math.max(44, nCol.implicitHeight + 12)
                radius: Theme.radiusSm
                color: nMa.containsMouse ? Theme.hover : Theme.inactiveBg
                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 6; bottomMargin: 6 }
                    spacing: 8
                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.fillHeight: true
                        radius: 3
                        color: (modelData.urgency ?? 0) === 2 ? Theme.error : Theme.accent
                    }
                    ColumnLayout {
                        id: nCol
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            text: (modelData.appName || "App") + (modelData.summary ? " · " + modelData.summary : "")
                            color: Theme.text
                            font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: (modelData.body || "") !== ""
                            text: modelData.body || ""
                            color: Theme.dimText
                            font { family: Theme.fontFamily; pixelSize: 10 }
                        }
                        RowLayout {
                            visible: (modelData.actions || []).length > 0
                            Repeater {
                                model: modelData.actions || []
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: actTxt.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: Theme.radiusSm
                                    color: actMa.containsMouse ? Theme.hoverStrong : Theme.wellSoft
                                    Text {
                                        id: actTxt
                                        anchors.centerIn: parent
                                        text: modelData.text || "Open"
                                        color: Theme.text
                                        font { family: Theme.fontFamily; pixelSize: 10 }
                                    }
                                    MouseArea { id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() }
                                }
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignTop
                        text: "×"
                        color: nXMa.containsMouse ? Theme.error : Theme.dimText
                        font.pixelSize: 14
                        MouseArea { id: nXMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysState.dismissNotification(modelData) }
                    }
                }
            }
        }
        Text {
            visible: SysState.notifications.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "All caught up. Enjoy the silence."
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 11 }
        }
    }
}
