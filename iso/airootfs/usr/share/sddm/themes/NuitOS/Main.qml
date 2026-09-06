import QtQuick 2.15
import SDDMComponents 2.0

Greeter {
    id: root

    Rectangle {
        anchors.fill: parent
        color: "#1E1E1E"

        // Background image
        Image {
            id: backgroundImage
            anchors.fill: parent
            source: "/usr/share/backgrounds/nuitos.png"
            fillMode: Image.PreserveAspectCrop
            visible: source != ""
        }

        // Semi-transparent overlay
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
        }

        // Center container
        Column {
            anchors.centerIn: parent
            spacing: 20

            // Logo
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "/usr/share/sddm/themes/NuitOS/logo.svg"
                sourceSize.width: 128
                sourceSize.height: 128
                visible: status == Image.Ready
            }

            // Username
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userModel.lastUser || ""
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 24
                font.bold: true
                color: "#FFFFFF"
            }

            // Password input
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 40
                radius: 10
                color: "#2A2A2A"
                border.color: "#444444"
                border.width: 1

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    echoMode: TextInput.Password
                    clip: true
                    focus: true
                    enabled: !loginScreen.loginInProgress

                    Keys.onReturnPressed: loginScreen.login()
                    Keys.onEnterPressed: loginScreen.login()
                }

                // Placeholder
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: "Password"
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                    color: "#666666"
                    visible: passwordInput.text.length === 0
                }
            }

            // Login button
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 40
                radius: 10
                color: loginButton.pressed ? "#2A6DBB" : "#3584E4"

                Text {
                    anchors.centerIn: parent
                    text: "Login"
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#FFFFFF"
                }

                MouseArea {
                    id: loginButton
                    anchors.fill: parent
                    onClicked: loginScreen.login()
                }
            }

            // Session selector
            ComboBox {
                id: sessionCombo
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                model: sessionModel
                textRole: "display"
                currentIndex: sessionModel.lastIndex
            }

            // Power buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // Shutdown
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: shutdownArea.pressed ? "#C0392B" : "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        font.pixelSize: 18
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: shutdownArea
                        anchors.fill: parent
                        onClicked: sddm.powerOff()
                    }
                }

                // Reboot
                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: rebootArea.pressed ? "#D68910" : "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⟳"
                        font.pixelSize: 18
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        onClicked: sddm.reboot()
                    }
                }
            }
        }

        // Clock
        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 30
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 48
            font.bold: true
            color: "#FFFFFF"
        }
    }

    Connections {
        target: loginScreen
        function onLoginSucceeded() {}
        function onLoginFailed() {
            passwordInput.text = ""
            passwordInput.focus = true
        }
    }
}
