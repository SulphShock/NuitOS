#!/bin/bash
# assemble.sh — build packages.x86_64.generated + staged airootfs from a profile.
# Usage: ./build/assemble.sh [profile] [--dry-run]
#   profile defaults to eww-walker-gnome. --dry-run prints, changes nothing.
# Does NOT call mkarchiso; run nuit-release.sh (or mkarchiso directly) after.
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${1:-eww-walker-gnome}"
[[ "$PROFILE" == "--dry-run" ]] && { PROFILE="eww-walker-gnome"; DRY=1; }
DRY="${DRY:-0}"
[[ "${2:-}" == "--dry-run" ]] && DRY=1
LIST="profiles/${PROFILE}.list"
[[ -f "$LIST" ]] || { echo "error: unknown profile $PROFILE ($(ls profiles/))" >&2; exit 1; }

declare -A PROVIDES_SEEN
PKGS=()
echo "profile: $PROFILE"
while read -r mod _; do
  [[ -z "$mod" || "$mod" == \#* ]] && continue
  M="modules/$mod"
  [[ -d "$M" ]] || { echo "note: module $mod has no dir yet (planned), skipping"; continue; }
  prov="$(awk -F= '/^provides=/{print $2}' "$M/module.conf" 2>/dev/null || echo none)"
  if [[ "$prov" != "none" && -n "${PROVIDES_SEEN[$prov]:-}" ]]; then
    echo "error: provides=$prov claimed by ${PROVIDES_SEEN[$prov]} and $mod" >&2; exit 1
  fi
  PROVIDES_SEEN[$prov]="$mod"
  [[ -f "$M/packages.list" ]] && mapfile -t -O "${#PKGS[@]}" PKGS < <(grep -vE '^\s*(#|$)' "$M/packages.list")
  echo "  + $mod (provides=$prov)"
done < "$LIST"

if [[ $DRY -eq 1 ]]; then
  echo "--- packages (${#PKGS[@]}) ---"
  printf '%s\n' "${PKGS[@]}"
  echo "--- provides ---"
  for k in "${!PROVIDES_SEEN[@]}"; do echo "  $k <= ${PROVIDES_SEEN[$k]}"; done
  exit 0
fi

printf '%s\n' "${PKGS[@]}" | awk '!seen[$0]++' > iso/packages.x86_64.generated
echo "wrote iso/packages.x86_64.generated (${#PKGS[@]} lines w/ dupes removed)"
./build/gen-pkgs-disk.sh
