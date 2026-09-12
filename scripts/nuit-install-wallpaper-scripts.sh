#!/bin/bash
# Puts the wallpaper crew in ~/.local/bin for dev machines.
# Install NuitOS wallpaper/theme scripts to ~/.local/bin (dev/local machines).
# The ISO ships these directly at /usr/local/bin instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN"

for script in \
    nuit-random-wallpaper \
    nuit-theme-bg-set \
    nuit-theme-bg-next \
    nuit-theme-bg-folder \
    nuit-theme-bg-current \
; do
    install -Dm755 "$SCRIPT_DIR/$script.sh" "$LOCAL_BIN/$script" 2>/dev/null \
        || install -Dm755 "$SCRIPT_DIR/$script" "$LOCAL_BIN/$script"
done

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo "Wallpaper scripts installed to $LOCAL_BIN"
echo "Run 'nuit-theme-bg-next' to cycle backgrounds, 'nuit-random-wallpaper' for a random one."