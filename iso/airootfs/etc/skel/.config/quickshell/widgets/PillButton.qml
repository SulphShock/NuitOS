import QtQuick
import ".."

Rectangle {
    id: root
    property string label: ""
    property bool active: false
    signal clicked()

    implicitHeight: 26
    implicitWidth: txt.implicitWidth + 22
    radius: height / 2
    color: ma.pressed ? Theme.hoverStrong
         : ma.containsMouse || active ? Theme.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        id: txt
        anchors.centerIn: parent
        text: root.label
        color: Theme.text
        font { family: Theme.fontFamily; pixelSize: Theme.fontPx; bold: true }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}