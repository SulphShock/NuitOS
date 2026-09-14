#!/bin/bash
# install.sh — fresh-Arch NuitOS installer
# Usage: curl -fsSL https://raw.githubusercontent.com/SulphShock/NuitOS/main/scripts/install.sh | bash
#        or: ./scripts/install.sh [--dry-run]
#
# Idempotent and resumable: safe to re-run.
# Style: matches scripts/nuit-release.sh (set -euo pipefail, note/warn/die).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

RED=$'\e[31m'; YEL=$'\e[33m'; GRN=$'\e[32m'; DIM=$'\e[2m'; RST=$'\e[0m'
note() { printf '%s[install]%s %s\n' "${DIM}" "${RST}" "$*"; }
warn() { printf '%s[warn]%s %s\n' "${YEL}" "${RST}" "$*"; }
die()  { printf '%s[error]%s %s\n' "${RED}" "${RST}" "$*" >&2; exit 1; }

# ── Preflight ────────────────────────────────────────────────────────────────
[[ -d "$REPO/configs" ]] || die "cannot find repo configs/ — run from the NuitOS repo"
command -v pacman >/dev/null 2>&1 || die "not an Arch-based system (pacman not found)"
ping -c1 -W3 archlinux.org >/dev/null 2>&1 || die "no network connection"

# Detect invoking user (handles sudo correctly)
REAL_USER="${SUDO_USER:-$USER}"
[[ "$REAL_USER" != "root" ]] || die "do not run as root — run as a normal user with sudo"
REAL_HOME="$(eval echo "~$REAL_USER")"
[[ -d "$REAL_HOME" ]] || die "home directory not found for $REAL_USER"

if [[ "$DRY_RUN" -eq 1 ]]; then
    note "dry-run mode — nothing will be modified"
fi

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        note "would run: $*"
    else
        "$@"
    fi
}

# ── Packages ─────────────────────────────────────────────────────────────────
# Parse iso/packages.x86_64, skip comments/blanks and ISO-only packages.
ISO_ONLY="mkinitcpio-archiso syslinux mkinitcpio intel-ucode amd-ucode plymouth"
PKGS=()
while IFS= read -r line; do
    pkg="$(echo "$line" | sed 's/#.*//' | xargs)"
    [[ -z "$pkg" ]] && continue
    skip=0
    for ex in $ISO_ONLY; do
        [[ "$pkg" == "$ex" ]] && { skip=1; break; }
    done
    [[ "$skip" -eq 1 ]] && continue
    PKGS+=("$pkg")
done < "$REPO/iso/packages.x86_64"

note "installing ${#PKGS[@]} packages"
run sudo pacman -S --needed --noconfirm "${PKGS[@]}"

# ── Configs → ~/.config ──────────────────────────────────────────────────────
note "deploying configs to $REAL_HOME/.config"
CONF_DIRS=(quickshell ghostty nvim fastfetch Branding)
for d in "${CONF_DIRS[@]}"; do
    if [[ -d "$REPO/configs/$d" ]]; then
        run rsync -a --delete "$REPO/configs/$d/" "$REAL_HOME/.config/$d/"
    fi
done

# Hyprland (split config)
mkdir -p "$REAL_HOME/.config/hypr/shaders"
for f in hyprland.conf env.conf appearance.conf rules.conf autostart.conf bindings.conf bindings.lua hyprland.lua; do
    [[ -f "$REPO/configs/hyprland/$f" ]] && run cp -f "$REPO/configs/hyprland/$f" "$REAL_HOME/.config/hypr/$f"
done
[[ -f "$REPO/configs/hyprland/shaders/nuit-night-light.glsl" ]] && \
    run cp -f "$REPO/configs/hyprland/shaders/nuit-night-light.glsl" "$REAL_HOME/.config/hypr/shaders/"

# Hypridle, hyprlock, hyprpaper
for conf in hypridle/hypridle.conf hyprlock/hyprlock.conf hyprpaper/hyprpaper.conf; do
    src="$REPO/configs/$conf"
    dst="$REAL_HOME/.config/$(dirname "$conf")"
    [[ -f "$src" ]] && { mkdir -p "$dst"; run cp -f "$src" "$dst/"; }
done

# Nuit keybinds
mkdir -p "$REAL_HOME/.config/nuit"
[[ -f "$REPO/configs/nuit/keybinds.txt" ]] && run cp -f "$REPO/configs/nuit/keybinds.txt" "$REAL_HOME/.config/nuit/"

# ── Scripts → /usr/local/bin ─────────────────────────────────────────────────
note "installing scripts to /usr/local/bin"
SCRIPTS=()
# From configs/bin/
for s in "$REPO"/configs/bin/*; do
    [[ -f "$s" ]] && SCRIPTS+=("$s")
done
# From scripts/ (nuit-theme-bg-*, nuit-aur-install, nuit-installer, nuit-random-wallpaper, nuit)
for s in "$REPO"/scripts/nuit-theme-bg-* "$REPO/scripts/nuit-aur-install" "$REPO/scripts/nuit-installer" "$REPO/scripts/nuit"; do
    [[ -f "$s" ]] && SCRIPTS+=("$s")
done
# Random wallpaper (no .sh suffix in /usr/local/bin)
[[ -f "$REPO/scripts/nuit-random-wallpaper.sh" ]] && SCRIPTS+=("$REPO/scripts/nuit-random-wallpaper.sh")

for s in "${SCRIPTS[@]}"; do
    name="$(basename "$s")"
    # Drop .sh suffix for installed name
    name="${name%.sh}"
    run sudo install -Dm755 "$s" "/usr/local/bin/$name"
done

# ── Skel → user home (only missing files) ────────────────────────────────────
note "applying skel defaults (missing files only)"
SKEL="$REPO/iso/airootfs/etc/skel"
if [[ -d "$SKEL" ]]; then
    # .bash_profile (or .zprofile for zsh)
    for profile in .bash_profile .zprofile; do
        if [[ ! -f "$REAL_HOME/$profile" && -f "$SKEL/$profile" ]]; then
            run cp "$SKEL/$profile" "$REAL_HOME/$profile"
            run chown "$REAL_USER:$REAL_USER" "$REAL_HOME/$profile"
        fi
    done
fi

# ── Ownership ────────────────────────────────────────────────────────────────
note "fixing ownership for $REAL_USER"
run sudo chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"

# ── Services ─────────────────────────────────────────────────────────────────
note "enabling services"
run sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
run sudo systemctl enable --now bluetooth.service 2>/dev/null || true
# PipeWire user units
run sudo -u "$REAL_USER" systemctl --user enable --now pipewire.service 2>/dev/null || true
run sudo -u "$REAL_USER" systemctl --user enable --now pipewire-pulse.service 2>/dev/null || true
run sudo -u "$REAL_USER" systemctl --user enable --now wireplumber.service 2>/dev/null || true

# ── Shell → zsh ──────────────────────────────────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
    current_shell="$(getent passwd "$REAL_USER" | cut -d: -f7)"
    if [[ "$current_shell" != */zsh ]]; then
        note "changing shell to zsh for $REAL_USER"
        run sudo chsh -s "$(command -v zsh)" "$REAL_USER"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo
if [[ "$DRY_RUN" -eq 1 ]]; then
    note "dry-run complete — no changes made"
else
    note "${GRN}done.${RST} log out and back in (or reboot) for all changes to take effect."
fi
