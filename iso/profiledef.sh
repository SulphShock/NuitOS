#!/bin/bash
# Nuit OS archiso profile definition

profile_type="iso"

iso_name="NuitOS"
iso_label="NuitOS"
iso_publisher="Nuit OS <https://github.com/SulphShock/NuitOS>"
iso_application="Nuit OS - Arch Linux + Hyprland"
iso_version="$(date +%Y.%m.%d)"
install_dir="nuitos"
bootmodes=('bios.syslinux/legacy' 'uefi-x64.systemd-boot')
arch="x86_64"
encrypted_keymap="false"
airootfs_image_type="squashfs"
airootfs_manifest_pacman="nuitos"
