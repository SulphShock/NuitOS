import QtQuick
import ".."

// Volume / Brightness control: the button fills up with color based on its value,
// scrolled with the mouse wheel.
Rectangle {
    id: root
    property real value: 0.0
    property color fillColor: Theme.accent
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: true
    signal clicked()
    signal wheelAdjusted(int direction)

    implicitHeight: 52
    radius: Theme.radiusMd
    color: active ? Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.25)
                  : (ma.containsMouse ? Theme.hover : Theme.inactiveBg)
    Behavior on color { ColorAnimation { duration: 140 } }
    clip: true

    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }

    // Fill layer — rises with the value
    Rectangle {
        id: fill
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * root.value
        radius: root.radius
        color: Qt.rgba(0.21, 0.52, 0.89, 0.40)
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 12
        WhiteIcon {
            width: 20
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            source: Theme.icon(root.icon)
            tint: root.active ? "white" : Theme.foreground
            opacity: root.active ? 1 : 0.85
            Behavior on tint { ColorAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
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