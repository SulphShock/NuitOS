#!/bin/bash
# gen-pkgs-disk.sh — derive target install list from generated live list.
# Drops pkgs a daily-driver install never touches. Keeps order, dedups.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="iso/packages.x86_64.generated"
[[ -f "$SRC" ]] || SRC="iso/packages.x86_64"

# Live/installer-only — NOT installed to disk:
#   syslinux, mkinitcpio-archiso ... live boot infrastructure
#   arch-install-scripts ........... pacstrap/genfstab (install-time only)
#   gum ............................ installer TUI prompts only
#   gptfdisk, parted ............... repartitioning tools (pacman -S when needed;
#                                    GNOME Disks covers daily use via udisks)
# Deliberately KEPT on target (needed post-install):
#   cryptsetup ..................... encrypt hook on every kernel-update mkinitcpio
#   e2fsprogs, btrfs-progs ......... fsck hooks at boot
#   dosfstools ..................... fsck.vfat for the ESP
#   base-devel, gcc, make, pkgconf . yay AUR builds
#   efibootmgr ..................... boot order management
grep -vE '^\s*(#|$)' "$SRC" \
  | grep -vxE 'syslinux|mkinitcpio-archiso|arch-install-scripts|gum|gptfdisk|parted' \
  | awk '!seen[$0]++' \
  > iso/airootfs/usr/local/share/nuit/pkgs-disk.txt.generated
echo "wrote iso/airootfs/usr/local/share/nuit/pkgs-disk.txt.generated"
