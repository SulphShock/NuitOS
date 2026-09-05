#!/bin/sh
# Prints: Name<TAB>Exec<TAB>Icon for every launchable .desktop entry
for f in "$HOME/.local/share/applications"/*.desktop \
         /usr/local/share/applications/*.desktop \
         /usr/share/applications/*.desktop; do
    [ -f "$f" ] || continue
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