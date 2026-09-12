// Vinyl -- YouTube Music's face in the bar. Yellow disc while music plays.
// Left opens the player, right finds your browser tab (or opens one fresh).
import QtQuick
import Quickshell.Services.Mpris
import ".."

Item {
    id: root
    implicitWidth: 18
    implicitHeight: 18
    visible: player !== null

    property var player: Mpris.players.values.find(p => p.playbackState === MprisPlaybackState.Playing)
        ?? Mpris.players.values[0] ?? null
    property bool playing: (player?.playbackState ?? -1) === MprisPlaybackState.Playing

    Item {
        id: disc
        anchors.centerIn: parent
        width: 14
        height: 14

        Rectangle {
            anchors.fill: parent
            radius: 7
            color: root.playing ? Theme.yellow : Theme.dimText
            Behavior on color { ColorAnimation { duration: 200 } }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                color: "transparent"
                border.color: Theme.panelBg
                border.width: 1
            }
            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: 2
                radius: 1
                color: Theme.panelBg
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) SysState.ytTab()
            else SysState.toggleYouTubeMusic()
        }
        onWheel: function(wheel) {
            if (!root.player) return
            if (wheel.angleDelta.y > 0) root.player.next()
            else root.player.previous()
            wheel.accepted = true
        }
    }
}
