# NuitOS justfile — canonical: configs/ → live + ISO skel
# Usage: just diff | just deploy | just sync-check
REPO := justfile_directory()

diff:
    @echo "== configs/ vs live =="
    @diff -qr {{REPO}}/configs/quickshell ~/.config/quickshell || true
    @diff -q {{REPO}}/configs/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf || true
    @diff -q {{REPO}}/configs/hyprland/env.conf ~/.config/hypr/env.conf || true
    @diff -q {{REPO}}/configs/hyprland/appearance.conf ~/.config/hypr/appearance.conf || true
    @diff -q {{REPO}}/configs/hyprland/rules.conf ~/.config/hypr/rules.conf || true
    @diff -q {{REPO}}/configs/hyprland/autostart.conf ~/.config/hypr/autostart.conf || true
    @echo "== configs/ vs skel =="
    @diff -qr {{REPO}}/configs/quickshell {{REPO}}/iso/airootfs/etc/skel/.config/quickshell || true
    @diff -qr {{REPO}}/configs/hyprland {{REPO}}/iso/airootfs/etc/skel/.config/hypr || true
    @diff -qr {{REPO}}/configs/ghostty {{REPO}}/iso/airootfs/etc/skel/.config/ghostty || true
    @diff -qr {{REPO}}/configs/nvim {{REPO}}/iso/airootfs/etc/skel/.config/nvim || true

deploy:
    @echo "Deploy configs/ → ~/.config/ + scripts/ → ~/.local/bin/"
    @cp -a {{REPO}}/configs/quickshell/. ~/.config/quickshell/
    @cp -f {{REPO}}/configs/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf
    @cp -f {{REPO}}/configs/hyprland/env.conf ~/.config/hypr/env.conf
    @cp -f {{REPO}}/configs/hyprland/appearance.conf ~/.config/hypr/appearance.conf
    @cp -f {{REPO}}/configs/hyprland/rules.conf ~/.config/hypr/rules.conf
    @cp -f {{REPO}}/configs/hyprland/autostart.conf ~/.config/hypr/autostart.conf
    @cp -f {{REPO}}/configs/hyprland/bindings.conf ~/.config/hypr/bindings.conf
    @cp -f {{REPO}}/configs/hyprland/bindings.lua ~/.config/hypr/bindings.lua
    @cp -f {{REPO}}/configs/hyprland/hyprland.lua ~/.config/hypr/hyprland.lua
    @mkdir -p ~/.config/hypr/shaders
    @cp -f {{REPO}}/configs/hyprland/shaders/nuit-night-light.glsl ~/.config/hypr/shaders/
    @cp -f {{REPO}}/configs/bin/* ~/.local/bin/
    @cp -f {{REPO}}/scripts/nuit-theme-bg-* ~/.local/bin/
    @echo "Deployed. Restart Hyprland / qs to pick up."

sync-check:
    @{{REPO}}/scripts/nuit-release.sh --help >/dev/null 2>&1 || true
    @echo "Run drift guard via nuit-release.sh build (fails on drift)."
