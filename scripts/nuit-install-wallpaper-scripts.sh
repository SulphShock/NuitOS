#!/bin/bash

# Install NuitOS wallpaper scripts
# This script installs the wallpaper utilities to ~/.local/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"

# Create local bin directory if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Copy scripts
cp "$SCRIPT_DIR/nuit-random-wallpaper.sh" "$LOCAL_BIN/nuit-random-wallpaper"
cp "$SCRIPT_DIR/nuit-setup-wallpapers.sh" "$LOCAL_BIN/nuit-setup-wallpapers"

# Make scripts executable
chmod +x "$LOCAL_BIN/nuit-random-wallpaper"
chmod +x "$LOCAL_BIN/nuit-setup-wallpapers"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "Wallpaper scripts installed successfully!"
echo "Run 'nuit-setup-wallpapers' to copy system wallpapers to your local directory"
echo "Run 'nuit-random-wallpaper' to set a random wallpaper"