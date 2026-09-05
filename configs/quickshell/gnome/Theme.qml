pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Typography (HIG: Cantarell, 13px, bold for bar chrome)
    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property int    fontPx: 13
    readonly property int    fontPxSmall: 11

    // Geometry
    readonly property int barHeight: 32

    // Palette — panel #1E1E1E @ 95%; hover pill white @ 15%
    property color background:           "#1E1E1E"
    property color foreground:           "#FFFFFF"
    property color green:                "#78B159"
    property color blue:                 "#3584E4"
    property color yellow:               "#E28B30"
    property color panelBg:              "#F21E1E1E"
    property color menuBg:               "#F21E1E1E"
    property color hover:                "#26FFFFFF"
    property color hoverStrong:          "#40FFFFFF"
    property color inactiveBg:           "#1FFFFFFF"
    property color outline:              "#22FFFFFF"
    property color text:                 "#FFFFFF"
    property color dimText:              "#B3FFFFFF"
    property color accent:               "#3584E4"

    // Radii (GNOME shell menus ≈ 24, controls ≈ 14)
    readonly property int radiusLg: 24
    readonly property int radiusMd: 14
    readonly property int radiusSm: 10

    function icon(name) {
        let resolved = name
        if (resolved === "network-wired") resolved = "network-wired-symbolic"
        if (resolved === "network-wireless-disconnected-symbolic") resolved = "network-wireless-disabled-symbolic"
        if (resolved === "applications-system-symbolic") resolved = "preferences-system-symbolic"
        let folder = "status"
        if (resolved === "preferences-system-symbolic") folder = "categories"
        else if (resolved === "system-shutdown-symbolic") folder = "actions"
        else if (resolved === "network-wired-symbolic") folder = "devices"
        else if (resolved.startsWith("network-wireless-") && !resolved.startsWith("network-wireless-signal-") && !resolved.includes("disabled")) folder = "devices"
        return "file:///usr/share/icons/Adwaita/symbolic/" + folder + "/" + resolved + ".svg"
    }

    function applyTheme(theme) {
        if (theme.background) {
            background = theme.background
            panelBg = Qt.rgba(background.r, background.g, background.b, 0.95)
            menuBg = panelBg
        }
        if (theme.foreground) {
            foreground = theme.foreground
            text = foreground
            dimText = Qt.rgba(foreground.r, foreground.g, foreground.b, 0.7)
        }
        if (theme.green) green = theme.green
        if (theme.blue) blue = theme.blue
        if (theme.yellow) yellow = theme.yellow
        if (theme.blue) accent = theme.blue
    }
}