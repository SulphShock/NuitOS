#!/bin/bash
# nuit-random-wallpaper — set a random NuitOS background (persisted).
#
# Picks from the user's imported themes (~/.config/nuit/backgrounds) with the
# shipped defaults (/usr/share/backgrounds) as fallback, then applies through
# the canonical setter `nuit-theme-bg-set`, which:
#   - persists the choice in ~/.config/hypr/hyprpaper.conf (hyprpaper 0.8 syntax)
#   - applies it live via `hyprctl hyprpaper wallpaper 'mon,path,fit'`
#   - tracks the current image at ~/.config/nuit/current/background
# This keeps every wallpaper entry point (next/random/set) on one code path.

set -euo pipefail

SEARCH_DIRS=(
  "$HOME/.config/nuit/backgrounds"
  "/usr/share/backgrounds"
)

CANDIDATES=()
for dir in "${SEARCH_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r -d '' f; do
    CANDIDATES+=("$f")
  done < <(find "$dir" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) -print0 2>/dev/null)
done

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "nuit-random-wallpaper: no wallpapers found in ${SEARCH_DIRS[*]}" >&2
  exit 1
fi

# Avoid instantly re-showing the current image when there is more than one.
CURRENT=""
if [ -L "$HOME/.config/nuit/current/background" ]; then
  CURRENT="$(readlink -f "$HOME/.config/nuit/current/background" 2>/dev/null || true)"
fi

PICK="${CANDIDATES[$((RANDOM % ${#CANDIDATES[@]}))]}"
if [ -n "$CURRENT" ] && [ "$PICK" = "$CURRENT" ] && [ "${#CANDIDATES[@]}" -gt 1 ]; then
  PICK="${CANDIDATES[$(((RANDOM + 1) % ${#CANDIDATES[@]}))]}"
fi

if ! command -v nuit-theme-bg-set >/dev/null 2>&1; then
  echo "nuit-random-wallpaper: nuit-theme-bg-set not found" >&2
  exit 1
fi

exec nuit-theme-bg-set "$PICK"