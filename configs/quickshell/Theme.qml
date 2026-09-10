pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Typography — JetBrains Mono Nerd Font everywhere (UI + terminal face)
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

    // Semantic roles — widgets must use these, never hard-code hex.
    property color accentText:             "#1D2021"   // text/glyphs on accent fills
    property color accentTextDim:          "#E6EBDBB2" // secondary text on accent fills
    property color fgBright:             "#FBF1C7"   // emphasis on dark (today, selected)
    property color error:                "#FB4934"   // inline errors, destructive text
    property color danger:               "#CC241D"   // destructive fills (power, delete hover)
    property color scrim:                "#E61D2021" // fullscreen overlay dim
    property color wellSoft:             "#33EBDBB2" // search fields, list wells
    property color focusBorder:          "#66EBDBB2" // focused borders, scrollbars
    property color faintText:            "#99EBDBB2" // placeholders
    property color ghostText:            "#55EBDBB2" // out-of-month, de-emphasized

    // Radii — 24 panels / 14 controls / 10 rows+inputs.
    // Circles and pills use r = height/2 (chips, icon buttons, search field).
    readonly property int radiusLg: 24
    readonly property int radiusMd: 14
    readonly property int radiusSm: 10

    function icon(name) {
        let resolved = name
        if (resolved === "network-wired") resolved = "network-wired-symbolic"
        if (resolved === "network-wireless-disconnected-symbolic") resolved = "network-wireless-disabled-symbolic"
        if (resolved === "network-wireless-symbolic") resolved = "network-wireless-disabled-symbolic"
        if (resolved === "battery-level-100-charging-symbolic") resolved = "battery-level-100-charged-symbolic"
        if (resolved === "applications-system-symbolic") resolved = "preferences-system-symbolic"
        let folder = "status"
        if (resolved === "preferences-system-symbolic") folder = "categories"
        else if (resolved === "system-shutdown-symbolic") folder = "actions"
        else if (resolved === "network-wired-symbolic") folder = "devices"
        else if (resolved.startsWith("network-wireless-") && !resolved.startsWith("network-wireless-signal-") && !resolved.includes("disabled")) folder = "devices"
        return "file:///usr/share/icons/Adwaita/symbolic/" + folder + "/" + resolved + ".svg"
    }

    function tint(src, alpha) {
        return Qt.rgba(src.r, src.g, src.b, alpha)
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
            // All cream-tinted surfaces re-derive so contrast themes apply fully.
            dimText = tint(foreground, 0.7)
            hover = tint(foreground, 0.15)
            hoverStrong = tint(foreground, 0.25)
            inactiveBg = tint(foreground, 0.12)
            outline = tint(foreground, 0.13)
            wellSoft = tint(foreground, 0.2)
            focusBorder = tint(foreground, 0.4)
            faintText = tint(foreground, 0.6)
            ghostText = tint(foreground, 0.33)
        }
        if (theme.green) green = theme.green
        if (theme.blue) blue = theme.blue
        if (theme.yellow) yellow = theme.yellow
        if (theme.blue) accent = theme.blue
    }
}