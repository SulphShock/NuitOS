#!/bin/bash

# Wallpaper script for NuitOS
# Creates ~/.config/hypr/wallpapers if it doesn't exist
# Copies system wallpapers if available

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Create directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Copy default wallpapers from system locations
DEFAULT_WALLPAPERS=(
    "/usr/share/backgrounds"
    "/usr/share/wallpapers" 
    "/usr/share/pixmaps/wallpapers"
    "/usr/share/nitrogen/wallpapers"
    "/usr/share/xfce4/backdrops"
    "/usr/share/mate-backgrounds"
    "/usr/share/gnome-backgrounds"
)

for wp_dir in "${DEFAULT_WALLPAPERS[@]}"; do
    if [ -d "$wp_dir" ]; then
        echo "Copying wallpapers from $wp_dir..."
        find "$wp_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) -exec cp {} "$WALLPAPER_DIR/" \; 2>/dev/null || true
    fi
done

# Set permissions
chmod -R 755 "$WALLPAPER_DIR"

echo "Wallpaper setup complete. Wallpapers are available in $WALLPAPER_DIR"