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
            // Injected by Variants (one Scope per screen). `required` so a
            // missing injection fails loudly instead of misplacing windows.
            required property var modelData

            // ── The top bar ──
            TopBar { screen: scr.modelData }

            // ── Popup layer (Quick Settings + Calendar + Reminders) with click-away scrim ──
            PanelWindow {
                screen: scr.modelData
                visible: SysState.qsOpen || SysState.calOpen || SysState.settingsOpen || SysState.remOpen || SysState.btOpen || SysState.wifiOpen
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
                RemindersPanel {
                    visible: SysState.remOpen
                    anchors { top: parent.top; right: parent.right
                              topMargin: Theme.barHeight + 8; rightMargin: 8 }
                }
                BluetoothPanel {
                    visible: SysState.btOpen
                    anchors { top: parent.top; right: parent.right
                              topMargin: Theme.barHeight + 8; rightMargin: 8 }
                }
                WifiPanel {
                    visible: SysState.wifiOpen
                    anchors { top: parent.top; right: parent.right
                              topMargin: Theme.barHeight + 8; rightMargin: 8 }
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
                ActivitiesOverlay { anchors.fill: parent }
            }

            // ── First-run welcome (modal, once per user, no click-away) ──
            PanelWindow {
                screen: scr.modelData
                visible: SysState.welcomeOpen
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:gnome-welcome"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WelcomePanel { anchors.centerIn: parent }
            }
        }
    }

    // CLI hooks — e.g. Hyprland: bind = SUPER, S, exec, qs ipc call gsb toggleQuickSettings
    IpcHandler {
        target: "gsb"
        function toggleQuickSettings(): void { SysState.toggleQs() }
        function toggleCalendar(): void      { SysState.toggleCalendar() }
        function toggleActivities(): void    { SysState.toggleActivities() }
        function toggleSettings(): void      { SysState.toggleSettings() }
        function toggleReminders(): void     { SysState.toggleReminders() }
        function toggleBluetooth(): void     { SysState.toggleBluetooth() }
        function toggleWifi(): void          { SysState.toggleWifi() }
        function setBright(v: real): void    { SysState.setBrightness(v) }
    }
}