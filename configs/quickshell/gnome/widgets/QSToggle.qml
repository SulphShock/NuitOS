import QtQuick
import ".."

Rectangle {
    id: root
    property bool active: false
    property color activeColor: Theme.accent
    property string icon: ""
    property string customGlyph: ""
    property string title: ""
    property string subtitle: ""
    signal clicked()
    signal wheelAdjusted(int direction)

    implicitHeight: 52
    radius: Theme.radiusMd
    color: active ? root.activeColor : (ma.containsMouse ? Theme.hover : Theme.inactiveBg)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 12
        WhiteIcon {
            visible: root.customGlyph === ""
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            source: Theme.icon(root.icon)
            tint: root.active ? "white" : Theme.foreground
            opacity: root.active ? 1 : 0.85
        }
        Text {
            visible: root.customGlyph !== ""
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.customGlyph
            horizontalAlignment: Text.AlignHCenter
            color: root.active ? "white" : Theme.text
            font.pixelSize: 17
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: root.title
                color: root.active ? "white" : Theme.text
                font { family: Theme.fontFamily; pixelSize: Theme.fontPx; bold: true }
            }
            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                color: root.active ? "#E6FFFFFF" : Theme.dimText
                font { family: Theme.fontFamily; pixelSize: Theme.fontPxSmall }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: function(wheel) {
            root.wheelAdjusted(wheel.angleDelta.y > 0 ? 1 : -1)
            wheel.accepted = true
        }
    }
}