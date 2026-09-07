#!/bin/bash
# Nuit OS archiso profile definition


iso_name="NuitOS"
iso_label="NuitOS"
iso_publisher="Nuit OS <https://github.com/SulphShock/NuitOS>"
iso_application="Nuit OS - Arch Linux + Hyprland"
iso_version="$(date +%Y.%m.%d)"
install_dir="nuitos"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
