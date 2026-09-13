import QtQuick
import QtQuick.Layouts
import ".."

// First-run welcome card. Shown once per user (SysState.welcomeOpen),
// dismissed explicitly via either button or Escape — there is no
// click-away: a first run deserves a decision, not an accident.
Rectangle {
    id: card
    implicitWidth: 480
    implicitHeight: content.implicitHeight + 48
    radius: Theme.radiusLg
    color: Theme.menuBg
    border.color: Theme.outline
    border.width: 1
    focus: visible
    Keys.onEscapePressed: SysState.dismissWelcome()

    MouseArea { anchors.fill: parent }   // swallow clicks (no scrim behind us)

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Image {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                source: Qt.resolvedUrl("../assets/Logo.png")
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Welcome to NuitOS"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 18; bold: true }
                }
                Text {
                    text: "Arch Linux · Hyprland · gruvbox-dark"
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 11 }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.outline }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [
                    { keys: "Super + Space",  what: "Apps (find the installer here)" },
                    { keys: "Super + Return", what: "Terminal" },
                    { keys: "Super + F1",     what: "Every key, in full" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        Layout.preferredWidth: 130
                        text: modelData.keys
                        color: Theme.accentText
                        font { family: Theme.fontFamily; pixelSize: 11; bold: true }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.what
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 12 }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 36
                radius: 18
                color: installMa.containsMouse ? Theme.hoverStrong : Theme.accent
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "Install NuitOS…"
                    color: Theme.accentText
                    font { family: Theme.fontFamily; pixelSize: 13; bold: true }
                }
                MouseArea {
                    id: installMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SysState.dismissWelcome()
                        SysState.launch("ghostty -e nuit-installer")
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: exploreMa.containsMouse ? Theme.hover : Theme.inactiveBg
                Behavior on color { ColorAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: "Explore desktop"
                    color: Theme.text
                    font { family: Theme.fontFamily; pixelSize: 13 }
                }
                MouseArea {
                    id: exploreMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysState.dismissWelcome()
                }
            }
        }
    }
}
