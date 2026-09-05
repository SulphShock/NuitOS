#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "NuitOS Installer"
echo "================"

# Install packages
if [ -f "$REPO_DIR/pkgs/core.txt" ]; then
    echo "Installing packages..."
    sudo pacman -S --needed - < "$REPO_DIR/pkgs/core.txt"
fi

# Create symlinks
echo "Setting up configs..."

link_config() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ]; then
        echo "Backing up $dest -> ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi
    ln -sf "$src" "$dest"
    echo "Linked $src -> $dest"
}

# Hyprland
mkdir -p ~/.config/hypr
link_config "$REPO_DIR/configs/hyprland/hyprland.conf" ~/.config/hypr/hyprland.conf

# Waybar
mkdir -p ~/.config/waybar
link_config "$REPO_DIR/configs/waybar/config.jsonc" ~/.config/waybar/config.jsonc
link_config "$REPO_DIR/configs/waybar/style.css" ~/.config/waybar/style.css

# Kitty
mkdir -p ~/.config/kitty
link_config "$REPO_DIR/configs/kitty/kitty.conf" ~/.config/kitty/kitty.conf

# Zsh
link_config "$REPO_DIR/configs/zsh/.zshrc" ~/.zshrc

# Neovim
mkdir -p ~/.config/nvim
link_config "$REPO_DIR/configs/neovim/init.lua" ~/.config/nvim/init.lua

echo ""
echo "Done! Restart your session to apply changes."
