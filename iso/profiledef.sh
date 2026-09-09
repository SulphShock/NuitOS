#!/bin/bash
# Nuit OS archiso profile definition

iso_name="NuitOS"
iso_label="NUITOS"
iso_publisher="Nuit OS <https://github.com/SulphShock/NuitOS>"
iso_application="Nuit OS - Arch Linux + Hyprland"
iso_version="$(date +%Y.%m.%d)"
install_dir="nuitos"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_permissions=(
  [0]='root:root 0755'
  [1]='root:root 0644 etc/passwd etc/group etc/shadow etc/gshadow'
  [2]='root:root 0755 etc/pacman.d'
  [3]='root:root 0755 root'
)
