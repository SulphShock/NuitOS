pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Typography (HIG: Cantarell, 13px, bold for bar chrome)
    readonly property string fontFamily: "JetBrains Mono Nerd Font"
    readonly property int    fontPx: 13
    readonly property int    fontPxSmall: 11

    // Geometry
    readonly property int barHeight: 22

    // Palette — gruvbox dark: panel #282828 @ 95%; hover pill cream @ 15%
    property color background:           "#282828"
    property color foreground:           "#EBDBB2"
    property color green:                "#B8BB26"
    property color blue:                 "#83A598"
    property color yellow:               "#FABD2F"
    property color panelBg:              "#F2282828"
    property color menuBg:               "#F2282828"
    property color hover:                "#26EBDBB2"
    property color hoverStrong:          "#40EBDBB2"
    property color inactiveBg:           "#1FEBDBB2"
    property color outline:              "#22EBDBB2"
    property color text:                 "#EBDBB2"
    property color dimText:              "#B3EBDBB2"
    property color accent:               "#83A598"

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