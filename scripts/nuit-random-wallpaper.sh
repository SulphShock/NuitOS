#!/bin/bash

# Wallpaper randomizer for NuitOS
# Sets a random wallpaper from the wallpapers directory

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Create directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Find supported image files
SUPPORTED_EXTENSIONS=("jpg" "jpeg" "png" "webp" "jxl")
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

# Select a random wallpaper (re-picking if it's the one already showing)
if [ ${#WALLPAPERS[@]} -gt 0 ]; then
    RANDOM_WALLPAPER="${WALLPAPERS[$((RANDOM % ${#WALLPAPERS[@]}))]}"
    if [ ${#WALLPAPERS[@]} -gt 1 ]; then
        CURRENT=""
        [ -L "$HOME/.config/nuit/current/background" ] && \
            CURRENT="$(readlink -f "$HOME/.config/nuit/current/background" 2>/dev/null || true)"
        if [ -n "$CURRENT" ] && [ "$RANDOM_WALLPAPER" = "$CURRENT" ]; then
            RANDOM_WALLPAPER="${WALLPAPERS[$(((RANDOM + 1) % ${#WALLPAPERS[@]}))]}"
        fi
    fi
    echo "Setting wallpaper: $RANDOM_WALLPAPER"

    # Set wallpaper. hyprpaper 0.8 removed the `preload` IPC and the
    # `hyprpaper -i` setter: a bare invocation on a running daemon fails
    # silently, so talk to the live session via hyprctl IPC instead.
    # `wallpaper "MONITOR,PATH"` auto-loads the file; empty monitor targets all.
    if pgrep -x hyprpaper &> /dev/null && command -v hyprctl &> /dev/null; then
        if ! hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER" >/dev/null 2>&1; then
            MONITORS="$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}')"
            for m in $MONITORS; do
                hyprctl hyprpaper wallpaper "$m,$RANDOM_WALLPAPER" >/dev/null 2>&1 || true
            done
        fi
        notify-send -a Nuit "Wallpaper" "$(basename "$RANDOM_WALLPAPER")" 2>/dev/null || true
    elif command -v hyprpaper &> /dev/null; then
        hyprpaper -i "$RANDOM_WALLPAPER"
    else
        echo "hyprpaper not found, cannot set wallpaper"
    fi
else
    echo "No wallpapers found to set"
fi