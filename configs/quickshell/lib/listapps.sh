#!/bin/sh
# Prints: Name<TAB>Exec<TAB>Icon for every launchable .desktop entry
# Hidden: avahi-utils, qt v4l2 utils, xgps utils, hyprlauncher, volume control, hardware tools
HIDDEN="avahi|v4l2|xgps|hyprlauncher|volume contro|pavucontrol|volumeicon|pulseaudio|hardinfo|cpu-x|lshw|hardware"

APP_DIRS="$HOME/.local/share/applications /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications $HOME/.local/share/flatpak/exports/share/applications"
ICON_DIRS="/usr/share/icons/hicolor /var/lib/flatpak/exports/share/icons/hicolor $HOME/.local/share/flatpak/exports/share/icons/hicolor"

resolve_icon() {
    local name="$1"
    [ -z "$name" ] && return
    case "$name" in
        /*) echo "$name"; return ;;
    esac
    local found
    found=$(find $ICON_DIRS -type f \( -name "${name}.svg" -o -name "${name}.png" \) -path "*/apps/*" 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "$found"
    else
        echo "$name"
    fi
}

for dir in $APP_DIRS; do
    for f in "$dir"/*.desktop; do
        [ -f "$f" ] || continue
        basename="${f##*/}"
        echo "$basename" | grep -qiE "$HIDDEN" && continue
        grep -iE "$HIDDEN" "$f" | grep -q . && continue
        awk -F= '
            /^\[Desktop Entry\]/ { inblock = 1; next }
            /^\[/                { inblock = 0 }
            inblock && /^Type=/       { type = $2 }
            inblock && /^NoDisplay=/  { nod  = $2 }
            inblock && /^Name=/       { name = $2 }
            inblock && /^Exec=/       { ex   = $2 }
            inblock && /^Icon=/       { ico  = $2 }
            END {
                if (type == "Application" && nod != "true" && ex != "")
                    printf "%s\t%s\t%s\n", name, ex, ico
            }' "$f"
    done
done | while IFS='	' read -r name exec icon; do
    printf "%s\t%s\t%s\n" "$name" "$exec" "$(resolve_icon "$icon")"
done
