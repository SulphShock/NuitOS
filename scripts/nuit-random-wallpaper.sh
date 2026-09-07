#!/bin/bash

# Wallpaper randomizer for NuitOS
# Sets a random wallpaper from the wallpapers directory

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Create directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Find supported image files
SUPPORTED_EXTENSIONS=("jpg" "jpeg" "png" "webp")
WALLPAPERS=()

for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    while IFS= read -r -d '' file; do
        WALLPAPERS+=("$file")
    done < <(find "$WALLPAPER_DIR" -type f -name "*.$ext" -print0 2>/dev/null)
done

# If no wallpapers found, copy default one
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR, copying default..."
    DEFAULT_WALLPAPER="/usr/share/backgrounds"
    if [ -d "$DEFAULT_WALLPAPER" ]; then
        cp "$DEFAULT_WALLPAPER"/*.jpg "$WALLPAPER_DIR/" 2>/dev/null || true
        cp "$DEFAULT_WALLPAPER"/*.png "$WALLPAPER_DIR/" 2>/dev/null || true
    fi
    
    # Try to copy from system locations
    SYSTEM_WALLPAPERS=("/usr/share/wallpapers" "/usr/share/backgrounds" "/usr/share/pixmaps/wallpapers")
    for wp_dir in "${SYSTEM_WALLPAPERS[@]}"; do
        if [ -d "$wp_dir" ]; then
            find "$wp_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -exec cp {} "$WALLPAPER_DIR/" \; 2>/dev/null || true
        fi
    done
    
    # Retry finding wallpapers after copying defaults
    for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
        while IFS= read -r -d '' file; do
            WALLPAPERS+=("$file")
        done < <(find "$WALLPAPER_DIR" -type f -name "*.$ext" -print0 2>/dev/null)
    done
fi

# If still no wallpapers, create a simple fallback
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "Creating fallback wallpaper..."
    convert -size 1920x1080 gradient:blue-black "$WALLPAPER_DIR/fallback.jpg" 2>/dev/null || true
    WALLPAPERS=("$WALLPAPER_DIR/fallback.jpg")
fi

# Select random wallpaper
if [ ${#WALLPAPERS[@]} -gt 0 ]; then
    RANDOM_WALLPAPER="${WALLPAPERS[$((RANDOM % ${#WALLPAPERS[@]}))]}"
    echo "Setting wallpaper: $RANDOM_WALLPAPER"
    
    # Set wallpaper with hyprpaper
    if command -v hyprpaper &> /dev/null; then
        hyprpaper -i "$RANDOM_WALLPAPER"
    else
        echo "hyprpaper not found, cannot set wallpaper"
    fi
else
    echo "No wallpapers found to set"
fi