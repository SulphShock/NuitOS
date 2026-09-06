#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║        NuitOS Installer              ║"
echo "║   Arch Linux + Hyprland              ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# Must be root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Run as root${NC}"
    echo "Usage: sudo ./install.sh"
    exit 1
fi

# ── Disk Selection ──────────────────────────────────────────
echo -e "${CYAN}[1/7] Disk Selection${NC}"
echo "Available disks:"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop\|sr\|ram"
echo ""
read -p "Target disk (e.g. /dev/sda): " TARGET_DISK

if [ ! -b "$TARGET_DISK" ]; then
    echo -e "${RED}ERROR: $TARGET_DISK is not a block device${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: ALL DATA on $TARGET_DISK will be erased!${NC}"
read -p "Type 'yes' to confirm: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# ── Partitioning ────────────────────────────────────────────
echo -e "${CYAN}[2/7] Partitioning $TARGET_DISK${NC}"

# Wipe and partition
parted -s "$TARGET_DISK" -- mklabel gpt
parted -s "$TARGET_DISK" -- mkpart ESP fat32 1MiB 513MiB
parted -s "$TARGET_DISK" -- set 1 esp on
parted -s "$TARGET_DISK" -- mkpart root ext4 513MiB 100%

# Wait for partitions
partprobe "$TARGET_DISK"
sleep 2

# Determine partition names
if [[ "$TARGET_DISK" == *"nvme"* ]] || [[ "$TARGET_DISK" == *"mmcblk"* ]]; then
    ESP_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
else
    ESP_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
fi

# Format
mkfs.fat -F32 "$ESP_PART"
mkfs.ext4 -F "$ROOT_PART"

# Mount
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$ESP_PART" /mnt/boot

# ── Base Install ────────────────────────────────────────────
echo -e "${CYAN}[3/7] Installing base system${NC}"
pacstrap /mnt base linux linux-firmware nano vim git sudo networkmanager

# ── Generate fstab ──────────────────────────────────────────
echo -e "${CYAN}[4/7] Generating fstab${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

# ── Chroot Config ──────────────────────────────────────────
echo -e "${CYAN}[5/7] Configuring system${NC}"

arch-chroot /mnt /bin/bash << 'CHROOT'
set -e

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "nuitos" > /etc/hostname

# Initramfs
mkinitcpio -P

# Bootloader
bootctl install

cat > /boot/loader/loader.conf << EOF
default  arch.conf
timeout  5
console-mode max
editor   no
EOF

cat > /boot/loader/entries/arch.conf << EOF
title   NuitOS
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value $(cat /proc/mounts | grep " / " | awk '{print $1}')) rw
EOF

# User setup
read -p "Enter username: " USERNAME
useradd -m -G wheel,audio,video,storage -s /bin/zsh "$USERNAME"
echo "Set password for $USERNAME:"
passwd "$USERNAME"

# Sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel

# Enable services
systemctl enable NetworkManager
systemctl enable sddm

CHROOT

# ── Install Packages ───────────────────────────────────────
echo -e "${CYAN}[6/7] Installing NuitOS packages${NC}"
arch-chroot /mnt pacman -S --needed --noconfirm - < "$REPO_DIR/pkgs/core.txt"

# ── Deploy Configs ─────────────────────────────────────────
echo -e "${CYAN}[7/7] Deploying NuitOS configs${NC}"

# SDDM theme
arch-chroot /mnt mkdir -p /usr/share/sddm/themes/NuitOS
cp -r "$REPO_DIR/iso/airootfs/usr/share/sddm/themes/NuitOS/"* /mnt/usr/share/sddm/themes/NuitOS/

# Hyprland
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/hypr
ln -sf "$REPO_DIR/configs/hyprland/hyprland.conf" /mnt/home/"$USERNAME"/.config/hypr/hyprland.conf

# Quickshell
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/quickshell
cp -r "$REPO_DIR/configs/quickshell/"* /mnt/home/"$USERNAME"/.config/quickshell/

# Neovim
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/nvim
cp -r "$REPO_DIR/configs/nvim/"* /mnt/home/"$USERNAME"/.config/nvim/

# Zsh
arch-chroot /mnt chsh -s /bin/zsh "$USERNAME"

# Fix permissions
arch-chroot /mnt chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  NuitOS installation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Reboot and remove the install media."
echo "Login with the user you created."
