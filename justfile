# NuitOS justfile — canonical: configs/ → live + ISO skel
# Usage: just diff | just deploy | just sync-check
REPO := justfile_directory()

diff:
    @echo "== configs/ vs live (informational, live machine may differ) =="
    @diff -qr {{REPO}}/configs/quickshell ~/.config/quickshell || true
    @diff -q {{REPO}}/configs/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf || true
    @diff -q {{REPO}}/configs/hyprland/env.conf ~/.config/hypr/env.conf || true
    @diff -q {{REPO}}/configs/hyprland/appearance.conf ~/.config/hypr/appearance.conf || true
    @diff -q {{REPO}}/configs/hyprland/rules.conf ~/.config/hypr/rules.conf || true
    @diff -q {{REPO}}/configs/hyprland/autostart.conf ~/.config/hypr/autostart.conf || true
    @diff -q {{REPO}}/configs/hyprland/bindings.conf ~/.config/hypr/bindings.conf || true
    @echo "== configs/ vs skel (must be silent; fails the build on drift) =="
    @diff -q {{REPO}}/configs/hyprland/hyprland.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/hyprland.conf
    @diff -q {{REPO}}/configs/hyprland/hyprland.lua {{REPO}}/iso/airootfs/etc/skel/.config/hypr/hyprland.lua
    @diff -q {{REPO}}/configs/hyprland/bindings.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/bindings.conf
    @diff -q {{REPO}}/configs/hyprland/bindings.lua {{REPO}}/iso/airootfs/etc/skel/.config/hypr/bindings.lua
    @diff -q {{REPO}}/configs/hyprland/env.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/env.conf
    @diff -q {{REPO}}/configs/hyprland/appearance.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/appearance.conf
    @diff -q {{REPO}}/configs/hyprland/rules.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/rules.conf
    @diff -q {{REPO}}/configs/hyprland/autostart.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/autostart.conf
    @diff -q {{REPO}}/configs/hyprland/shaders/nuit-night-light.glsl {{REPO}}/iso/airootfs/etc/skel/.config/hypr/shaders/nuit-night-light.glsl
    @diff -q {{REPO}}/configs/hyprpaper/hyprpaper.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/hyprpaper.conf
    @diff -q {{REPO}}/configs/hypridle/hypridle.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/hypridle.conf
    @diff -q {{REPO}}/configs/hyprlock/hyprlock.conf {{REPO}}/iso/airootfs/etc/skel/.config/hypr/hyprlock.conf
    @diff -q {{REPO}}/configs/nuit/keybinds.txt {{REPO}}/iso/airootfs/etc/skel/.config/nuit/keybinds.txt
    @diff -qr {{REPO}}/configs/quickshell {{REPO}}/iso/airootfs/etc/skel/.config/quickshell
    @diff -qr {{REPO}}/configs/ghostty {{REPO}}/iso/airootfs/etc/skel/.config/ghostty
    @diff -qr {{REPO}}/configs/nvim {{REPO}}/iso/airootfs/etc/skel/.config/nvim
    @diff -qr {{REPO}}/configs/fastfetch {{REPO}}/iso/airootfs/etc/skel/.config/fastfetch
    @diff -qr {{REPO}}/configs/Branding {{REPO}}/iso/airootfs/etc/skel/.config/Branding
    @diff -qr {{REPO}}/configs/gammastep {{REPO}}/iso/airootfs/etc/skel/.config/gammastep
    @diff -qr {{REPO}}/configs/wallpapers/default {{REPO}}/iso/airootfs/usr/share/backgrounds
    @diff -qr {{REPO}}/configs/wallpapers/default {{REPO}}/iso/airootfs/etc/skel/.config/nuit/backgrounds
    @test ! -s {{REPO}}/iso/airootfs/etc/machine-id
    @echo "skel in sync."

deploy:
    @echo "Deploy configs/ → ~/.config/ + scripts/ → ~/.local/bin/"
    @cp -a {{REPO}}/configs/quickshell/. ~/.config/quickshell/
    @cp -a {{REPO}}/configs/ghostty/. ~/.config/ghostty/
    @cp -a {{REPO}}/configs/nvim/. ~/.config/nvim/
    @cp -a {{REPO}}/configs/fastfetch/. ~/.config/fastfetch/
    @cp -a {{REPO}}/configs/Branding/. ~/.config/Branding/
    @cp -a {{REPO}}/configs/gammastep/. ~/.config/gammastep/
    @mkdir -p ~/.config/nuit
    @cp -f {{REPO}}/configs/nuit/keybinds.txt ~/.config/nuit/keybinds.txt
    @cp -f {{REPO}}/configs/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf
    @cp -f {{REPO}}/configs/hyprland/env.conf ~/.config/hypr/env.conf
    @cp -f {{REPO}}/configs/hyprland/appearance.conf ~/.config/hypr/appearance.conf
    @cp -f {{REPO}}/configs/hyprland/rules.conf ~/.config/hypr/rules.conf
    @cp -f {{REPO}}/configs/hyprland/autostart.conf ~/.config/hypr/autostart.conf
    @cp -f {{REPO}}/configs/hyprland/bindings.conf ~/.config/hypr/bindings.conf
    @cp -f {{REPO}}/configs/hyprland/bindings.lua ~/.config/hypr/bindings.lua
    @cp -f {{REPO}}/configs/hyprland/hyprland.lua ~/.config/hypr/hyprland.lua
    @cp -f {{REPO}}/configs/hypridle/hypridle.conf ~/.config/hypr/hypridle.conf
    @cp -f {{REPO}}/configs/hyprlock/hyprlock.conf ~/.config/hypr/hyprlock.conf
    @cp -f {{REPO}}/configs/hyprpaper/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
    @mkdir -p ~/.config/hypr/shaders
    @cp -f {{REPO}}/configs/hyprland/shaders/nuit-night-light.glsl ~/.config/hypr/shaders/
    @cp -f {{REPO}}/configs/bin/* ~/.local/bin/
    @cp -f {{REPO}}/scripts/nuit-theme-bg-* ~/.local/bin/
    @echo "Deployed. Restart Hyprland / qs to pick up."

sync-check:
    @{{REPO}}/scripts/nuit-release.sh --help >/dev/null 2>&1 || true
    @echo "Run drift guard via nuit-release.sh build (fails on drift)."
