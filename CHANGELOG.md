# Changelog

## v1.0.0 (2026-10-03 target)

Production-ready first release.

- Quickshell topbar is canonical: TimeHub replaces Planova+CalendarPanel; split Hyprland config replaces monolith; hyprshade night-light replaces gammastep; systemd user units own hyprpaper/hypridle; nautilus replaces thunar; terminal ghostty, browser firefox, media mpv.
- Installer: all 7 blockers fixed — live carries installer deps, sudo preserves args, `--dry-run` is read-only with no GO prompt and honest SKIP/BIOS, LUKS encrypts swap (swapfile in cryptroot, no hibernation), `/etc/shadow` 0640, skel tty-hijack guarded to live user.
- Diet: removed chromium vlc sddm/sddm-kcm swaylock mako tlp full-X11 thunar dupes; wallpapers 39M PNG/JPG → 1.9M WebP (originals are release assets).
- Guardrails: `just diff/deploy`, drift CI + build CI, TESTING.md evidence bundle, SHA256 on releases.
