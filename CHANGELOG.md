# Changelog

## Unreleased

- Added `AGENTS.md` with repo ground truth and agent constraints.
- Added `scripts/install.sh` for fresh-Arch installs (idempotent, `--dry-run`).
- Added `SECURITY.md` with vulnerability disclosure contact.
- Fixed CI: added shellcheck lint job, sudo in build/release workflows.
- Fixed dead waybar layerrules in Hyprland config (now quickshell).
- Fixed `SC1102` shellcheck error in `nuit-wallpaper-flare`.
- Fixed `iso/profiledef.sh`: dynamic version from `git describe`, trailing space removed.

## v1.0.0 (2026-10-03 target)

Production-ready first release.

- Quickshell topbar is canonical: TimeHub replaces Planova+CalendarPanel; split Hyprland config replaces monolith; hyprshade night-light replaces gammastep; systemd user units own hyprpaper/hypridle; nautilus replaces thunar; terminal ghostty, browser firefox, media mpv.
- Installer: all 7 blockers fixed — live carries installer deps, sudo preserves args, `--dry-run` is read-only with no GO prompt and honest SKIP/BIOS, LUKS encrypts swap (swapfile in cryptroot, no hibernation), `/etc/shadow` 0640, skel tty-hijack guarded to live user.
- Diet: removed chromium vlc sddm/sddm-kcm swaylock mako tlp full-X11 thunar dupes; wallpapers 39M PNG/JPG → 1.9M WebP (originals are release assets).
- Guardrails: `just diff/deploy`, drift CI + build CI, TESTING.md evidence bundle, SHA256 on releases.
