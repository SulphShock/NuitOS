#!/bin/bash
# os-update -- full system refresh, run where you can see it.
# Clock, pacman, AUR, flatpak. Interactive on purpose: sudo and big
# decisions should never happen behind your back.
set -u

say() { printf '\n==> %s\n' "$1"; }

say "Clock sync"
sudo timedatectl set-ntp true 2>/dev/null || true
timedatectl 2>/dev/null | grep -E "Local time|Universal|NTP|synchronized" || true

say "System packages (pacman -Syu)"
sudo pacman -Syu

if command -v yay >/dev/null 2>&1; then
  say "AUR (yay -Syu)"
  yay -Syu
elif command -v paru >/dev/null 2>&1; then
  say "AUR (paru -Syu)"
  paru -Syu
fi

if command -v flatpak >/dev/null 2>&1; then
  say "Flatpak"
  flatpak update
fi

say "All done"
notify-send -a Nuit "System update finished" 2>/dev/null || true
read -rp "Press enter to close... " _
