import QtQuick
import QtQuick.Effects

Item {
    id: root
    property url source
    property color tint: "white"
    property real size: 20
    implicitWidth: size
    implicitHeight: size

    Image {
        id: sourceImage
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        visible: false
        sourceSize.width: root.size
        sourceSize.height: root.size
    }

    MultiEffect {
        anchors.fill: parent
        source: sourceImage
        brightness: 1
        contrast: 1
        saturation: 0
        colorization: 1
        colorizationColor: root.tint
    }
}
