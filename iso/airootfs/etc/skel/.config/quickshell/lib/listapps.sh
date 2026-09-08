#!/bin/sh
# Prints: Name<TAB>Exec<TAB>Icon for every launchable .desktop entry
# Sources: pacman/yay (/usr/share, /usr/local, ~/.local) + flatpak (system + user)
# Icon: absolute path when found, else themed name (QML resolves via Quickshell.iconPath)

APP_DIRS="$HOME/.local/share/applications /usr/local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications $HOME/.local/share/flatpak/exports/share/applications"

# Hidden on request: avahi utils, xgps utils, hardware locality (lstopo),
# Nuit OS Installer, Volume Control. Matched against the .desktop basename + Name.
HIDDEN="avahi|bssh|bvnc|xgps|v4l2|qv4l2|qvidcap|lstopo|hardware locality|nuit-installer|nuit os installer|pavucontrol|volume control"

resolve_icon() {
    local name="$1"
    [ -z "$name" ] && { echo "application-x-executable"; return; }
    case "$name" in
        /*)
            # absolute path: add extension if missing
            if [ -f "$name" ]; then echo "$name"; return; fi
            for ext in .svg .png .xpm; do
                if [ -f "$name$ext" ]; then echo "$name$ext"; return; fi
            done
            echo "$name"; return ;;
        *.*)
            # already has extension but relative? keep as-is, QML falls back
            case "$name" in *.png|*.svg|*.xpm) echo "$name"; return ;; esac
            ;;
    esac
    local found=""
    # 1) pixmaps (vscode, etc.): /usr/share/pixmaps/<name>.{png,svg,xpm}
    for ext in png svg xpm; do
        if [ -f "/usr/share/pixmaps/${name}.${ext}" ]; then
            echo "/usr/share/pixmaps/${name}.${ext}"; return
        fi
        if [ -f "$HOME/.local/share/pixmaps/${name}.${ext}" ]; then
            echo "$HOME/.local/share/pixmaps/${name}.${ext}"; return
        fi
    done
    # 2) fast path: exact stem match under well-known icon roots (prefer big/svg)
    #    covers hicolor, Adwaita, AdwaitaLegacy + flatpak exports
    found=$(find /usr/share/icons "$HOME/.local/share/icons" \
        /var/lib/flatpak/exports/share/icons "$HOME/.local/share/flatpak/exports/share/icons" \
        -type f \( -name "${name}.svg" -o -name "${name}.png" \) 2>/dev/null \
        | sort -r | head -1)
    if [ -n "$found" ]; then echo "$found"; return; fi
    # 3) flatpak per-app exports (e.g. com.obsproject.Studio lives only here)
    found=$(find /var/lib/flatpak/app "$HOME/.local/share/flatpak/app" \
        -path "*export/share/icons*" -type f \( -name "${name}.svg" -o -name "${name}.png" \) 2>/dev/null \
        | sort -r | head -1)
    if [ -n "$found" ]; then echo "$found"; return; fi
    # 4) any hicolor scalable/apps hit for xpm
    found=$(find /usr/share/icons/hicolor -type f -name "${name}.xpm" -path "*/apps/*" 2>/dev/null | head -1)
    if [ -n "$found" ]; then echo "$found"; return; fi
    # 5) fallback: themed name, QML resolves via Quickshell.iconPath()
    echo "$name"
}

# Use find (handles large dirs). NOTE: many entries are symlinks
# (libreoffice -> /usr/lib/libreoffice/..., flatpak -> ../../../app/...),
# so match both regular files and symlinks.
for dir in $APP_DIRS; do
    [ -d "$dir" ] || continue
    find "$dir" -maxdepth 1 -name "*.desktop" \( -type f -o -type l \) 2>/dev/null
done | while IFS= read -r f; do
    [ -e "$f" ] || continue
    echo "${f##*/}" | grep -qiE "$HIDDEN" && continue
    awk '
        /^\[Desktop Entry\]/ { inblock = 1; next }
        /^\[/                { inblock = 0; next }
        inblock && /^Type=Application$/      { type_ok = 1 }
        inblock && /^NoDisplay=true$/        { nod = 1 }
        inblock && /^Hidden=true$/           { hid = 1 }
        inblock && /^Name=/ {
            s = $0; sub(/^[^=]*=/, "", s); if (name == "") name = s
        }
        inblock && /^Exec=/ {
            s = $0; sub(/^[^=]*=/, "", s); if (ex == "") ex = s
        }
        inblock && /^Icon=/ {
            s = $0; sub(/^[^=]*=/, "", s); if (ico == "") ico = s
        }
        END {
            if (type_ok && !nod && !hid && ex != "" && name != "")
                printf "%s\t%s\t%s\n", name, ex, ico
        }' "$f"
done | grep -viE "$HIDDEN" | sort -t "	" -k1,1 -f | awk -F'\t' '!seen[tolower($1)]++' | while IFS='	' read -r name exec icon; do
    printf "%s\t%s\t%s\n" "$name" "$exec" "$(resolve_icon "$icon")"
done
