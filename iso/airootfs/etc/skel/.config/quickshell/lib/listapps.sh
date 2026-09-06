#!/bin/sh
# Prints: Name<TAB>Exec<TAB>Icon for every launchable .desktop entry
# Hidden: avahi-utils, qt v4l2 utils, xgps utils, hyprlauncher, volume control, hardware tools
HIDDEN="avahi|v4l2|xgps|hyprlauncher|volume contro|pavucontrol|volumeicon|pulseaudio|hardinfo|cpu-x|lshw|hardware"
for f in "$HOME/.local/share/applications"/*.desktop \
         /usr/local/share/applications/*.desktop \
         /usr/share/applications/*.desktop; do
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