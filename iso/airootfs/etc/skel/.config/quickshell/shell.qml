import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "widgets"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: scr
            property var modelData

            // ── The top bar ──
            TopBar { screen: scr.modelData }

            // ── Popup layer (Quick Settings + Calendar) with click-away scrim ──
            PanelWindow {
                screen: scr.modelData
                visible: SysState.qsOpen || SysState.calOpen || SysState.settingsOpen
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:gnome-popups"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                MouseArea { anchors.fill: parent; onClicked: SysState.closeAll() }

                QuickSettings {
                    visible: SysState.qsOpen
                    anchors { top: parent.top; right: parent.right
                              topMargin: Theme.barHeight + 8; rightMargin: 8 }
                }
                CalendarPanel {
                    visible: SysState.calOpen
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter
                              topMargin: Theme.barHeight + 8 }
                }
                SettingsPanel {
                    visible: SysState.settingsOpen
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter
                              topMargin: Theme.barHeight + 8 }
                }
            }

            // ── Activities overlay (modal, keyboard capture) ──
            PanelWindow {
                screen: scr.modelData
                visible: SysState.actOpen
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:gnome-activities"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                ActivitiesVerlay { anchors.fill: parent }
            }
        }
    }

    // CLI hooks — e.g. Hyprland: bind = SUPER, S, exec, qs ipc call gsb toggleQuickSettings
    IpcHandler {
        target: "gsb"
        function toggleQuickSettings() { SysState.toggleQs() }
        function toggleCalendar()      { SysState.toggleCalendar() }
        function toggleActivities()    { SysState.toggleActivities() }
        function toggleSettings()      { SysState.toggleSettings() }
    }
}