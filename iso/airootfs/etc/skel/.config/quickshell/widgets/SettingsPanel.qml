import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import Quickshell.Io
import ".."

Rectangle {
    id: panel
    implicitWidth: 980
    implicitHeight: 610
    radius: Theme.radiusLg
    color: Theme.menuBg
    property int section: 0
    property bool asciiMode: true
    property string wallpaperPath: ""
    property string screensaverImage: ""
    property string customAscii: "01001001\n  SULPHSHEL\n01010110"
    property var themes: []
    property var selectedTheme: null

    component ShellButton: Button {
        id: shellButton
        implicitHeight: 34
        leftPadding: 14
        rightPadding: 14
        contentItem: Text {
            text: shellButton.text
            color: shellButton.checked ? "white" : Theme.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font { family: Theme.fontFamily; pixelSize: 11; bold: shellButton.checked }
        }
        background: Rectangle {
            radius: Theme.radiusSm
            color: shellButton.checked ? Theme.accent
                : shellButton.hovered ? Theme.hover : Theme.inactiveBg
            border.color: shellButton.checked ? Theme.accent : Theme.outline
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    Process {
        id: themeLoader
        command: ["sh", "-c", "for file in " + Qt.resolvedUrl("../themes").toString().replace("file://", "") + "/*.json; do [ -f \"$file\" ] && cat \"$file\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const loaded = []
                for (const line of text.trim().split("\n")) {
                    if (line.trim() === "") continue
                    try {
                        const theme = JSON.parse(line)
                        if (theme.name && (theme.blue || theme.accent)) loaded.push(theme)
                    } catch (error) {
                        console.warn("Ignoring invalid theme extension", error)
                    }
                }
                panel.themes = loaded
            }
        }
    }

    Component.onCompleted: themeLoader.running = true

    FileDialog {
        id: imageDialog
        fileMode: FileDialog.OpenFile
        modality: Qt.ApplicationModal
        options: FileDialog.DontUseNativeDialog
        title: "Choose an image"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            if (panel.section === 1) panel.screensaverImage = selectedFile.toString()
            else panel.wallpaperPath = selectedFile.toString()
        }
    }
    function chooseImage() {
        imageDialog.open()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 170
            Layout.fillHeight: true
            radius: Theme.radiusMd
            color: Theme.inactiveBg
            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                Row {
                    spacing: 8
                    Image {
                        width: 26; height: 26
                        source: Qt.resolvedUrl("../assets/Logo.png")
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: "CONTROL"
                        color: Theme.text
                        font { family: Theme.fontFamily; pixelSize: 12; bold: true }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: Theme.outline }
                Repeater {
                    model: ["Theme", "Screensaver", "Wallpaper"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: parent.width
                        height: 38
                        radius: 10
                        color: panel.section === index ? Theme.accent : navMouse.containsMouse ? Theme.hover : "transparent"
                        Text {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: panel.section === index ? "white" : Theme.text
                            font { family: Theme.fontFamily; pixelSize: 12; bold: panel.section === index }
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: panel.section = index
                        }
                    }
                }
                Item { height: 1; width: 1 }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "Explore more config → www.xxxxxxx.com"
                    color: Theme.dimText
                    font { family: Theme.fontFamily; pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: SysState.launch("xdg-open https://www.xxxxxxx.com") }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            Text {
                text: ["Theme", "Screensaver", "Wallpaper"][panel.section]
                color: Theme.text
                font { family: Theme.fontFamily; pixelSize: 18; bold: true }
            }

            Rectangle {
                visible: panel.section === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMd
                color: Theme.inactiveBg
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14
                        Text { text: "Theme"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 15; bold: true } }
                        Repeater {
                            model: panel.themes
                            delegate: Rectangle {
                                id: themeCard
                                required property var modelData
                                Layout.fillWidth: true
                                height: 42
                                radius: Theme.radiusSm
                                property bool selected: panel.selectedTheme === modelData
                                color: selected ? Theme.accent : themeMouse.containsMouse ? Theme.hover : Theme.inactiveBg
                                border.color: selected ? Theme.accent : Theme.outline
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                    text: modelData.name + "  /  " + modelData.variant
                                    color: themeCard.selected ? "white" : Theme.text
                                    font { family: Theme.fontFamily; pixelSize: 12; bold: themeCard.selected }
                                }
                                Row {
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    spacing: 4
                                    Repeater {
                                        model: [modelData.background, modelData.foreground, modelData.green, modelData.blue, modelData.yellow]
                                        delegate: Rectangle {
                                            required property string modelData
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: modelData
                                        }
                                    }
                                }
                                MouseArea {
                                    id: themeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        panel.selectedTheme = modelData
                                        Theme.applyTheme(modelData)
                                    }
                                }
                            }
                        }
                        Text {
                            visible: panel.themes.length === 0
                            text: "No theme extensions found"
                            color: Theme.dimText
                            font.family: Theme.fontFamily
                        }
                        Text { text: "Palette is supplied by the selected theme extension"; color: Theme.dimText; font { family: Theme.fontFamily; pixelSize: 11 } }
                        Item { Layout.fillHeight: true }
                    }
            }

            Rectangle {
                visible: panel.section === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMd
                color: Theme.inactiveBg
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    Text { text: "Screensaver content"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                    RowLayout {
                        Layout.fillWidth: true
                        ShellButton { text: "ASCII Art"; checkable: true; checked: panel.asciiMode; onClicked: panel.asciiMode = true }
                        ShellButton { text: "Image"; checkable: true; checked: !panel.asciiMode; onClicked: panel.asciiMode = false }
                        ShellButton { visible: !panel.asciiMode; text: "Upload image"; onClicked: panel.chooseImage() }
                    }
                    TextArea {
                        visible: panel.asciiMode
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        text: panel.customAscii
                        placeholderText: "Enter custom ASCII art"
                        wrapMode: TextEdit.NoWrap
                        font { family: Theme.fontFamily; pixelSize: 12 }
                        onTextChanged: panel.customAscii = text
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        radius: Theme.radiusMd; color: "#101010"
                        Image { anchors.fill: parent; anchors.margins: 16; visible: !panel.asciiMode && panel.screensaverImage !== ""; source: panel.screensaverImage; fillMode: Image.PreserveAspectFit }
                        Text { anchors.centerIn: parent; visible: panel.asciiMode || panel.screensaverImage === ""; text: panel.asciiMode ? panel.customAscii : "Choose an image"; color: Theme.accent; font { family: Theme.fontFamily; pixelSize: 18; bold: true } }
                    }
                }
            }

            Rectangle {
                visible: panel.section === 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMd
                color: Theme.inactiveBg
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text { text: "Wallpaper"; color: Theme.text; font { family: Theme.fontFamily; pixelSize: 13; bold: true } }
                    RowLayout {
                        Layout.fillWidth: true
                        ShellButton { text: "Choose wallpaper"; onClicked: panel.chooseImage() }
                    }
                    Text { Layout.fillWidth: true; text: panel.wallpaperPath === "" ? "No custom wallpaper selected" : panel.wallpaperPath; color: Theme.dimText; elide: Text.ElideMiddle; font.family: Theme.fontFamily }
                    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; radius: Theme.radiusMd; color: "#101010"
                        Image { anchors.fill: parent; anchors.margins: 12; source: panel.wallpaperPath; fillMode: Image.PreserveAspectFit; visible: panel.wallpaperPath !== "" }
                        Text { anchors.centerIn: parent; visible: panel.wallpaperPath === ""; text: "Wallpaper preview"; color: Theme.dimText; font.family: Theme.fontFamily }
                    }
                }
            }

        }
    }
}