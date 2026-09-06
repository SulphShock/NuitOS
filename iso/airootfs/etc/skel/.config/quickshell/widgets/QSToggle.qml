import QtQuick
import ".."

// Quick Settings control. Two flavors:
//   - plain toggle (filled: false) — the whole cell highlights in activeColor when active
//   - fill control (filled: true)  — a colored fill rises with `value` (volume/brightness)
Rectangle {
    id: root
    property real value: 0.0
    property bool filled: false
    property bool active: false
    property color activeColor: Theme.accent
    property color fillColor: Theme.accent
    property string icon: ""
    property string customGlyph: ""
    property string title: ""
    property string subtitle: ""
    signal clicked()
    signal wheelAdjusted(int direction)

    implicitHeight: 52
    radius: Theme.radiusMd
    color: root.active
        ? (root.filled ? Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.25)
                       : root.activeColor)
        : ma.pressed ? Theme.hoverStrong
        : (ma.containsMouse ? Theme.hover : Theme.inactiveBg)
    Behavior on color { ColorAnimation { duration: 120 } }
    clip: true

    // Fill layer — shows `value`, used by volume/brightness
    Rectangle {
        id: fill
        visible: root.filled
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * root.value
        radius: root.radius
        color: Qt.rgba(root.fillColor.r, root.fillColor.g, root.fillColor.b, 0.40)
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 12
        WhiteIcon {
            visible: root.customGlyph === ""
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            source: Theme.icon(root.icon)
            tint: root.active ? "white" : Theme.foreground
            opacity: root.active ? 1 : 0.85
            Behavior on tint { ColorAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
            NumberAnimation {
                id: iconPulse
                target: parent
                property: "rotation"
                from: -14
                to: 0
                duration: 200
                easing.type: Easing.OutBack
            }
            Connections {
                target: root
                function onActiveChanged() {
                    parent.rotation = 0
                    iconPulse.restart()
                }
            }
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