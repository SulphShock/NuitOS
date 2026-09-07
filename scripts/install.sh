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
echo "║        Nuit OS Installer              ║"
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
title   Nuit OS
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value $(cat /proc/mounts | grep " / " | awk '{print $1}')) rw
EOF

# User setup
read -p "Enter username: " USERNAME
useradd -m -G wheel,audio,video,storage,input -s /bin/zsh "$USERNAME"
echo "Set password for $USERNAME:"
passwd "$USERNAME"

# Sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel

# Enable services
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth

CHROOT

# ── Install Packages ───────────────────────────────────────
echo -e "${CYAN}[6/7] Installing Nuit OS packages${NC}"
arch-chroot /mnt pacman -S --needed --noconfirm - < "$REPO_DIR/pkgs/core.txt"

# ── Deploy Configs ─────────────────────────────────────────
echo -e "${CYAN}[7/7] Deploying Nuit OS configs${NC}"

# SDDM theme (Pixie)
arch-chroot /mnt bash -c '
git clone https://github.com/xCaptaiN09/pixie-sddm.git /tmp/pixie-sddm
cp -r /tmp/pixie-sddm /usr/share/sddm/themes/pixie
rm -rf /tmp/pixie-sddm
mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=pixie" > /etc/sddm.conf.d/theme.conf
'

# SDDM wallpaper helper
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/wallpapers/sddm
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/wallpapers/backgrounds/default
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/wallpapers/current
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.local/bin
cat > /mnt/home/"$USERNAME"/.local/bin/sddm-wallpaper << 'SCRIPT'
#!/bin/bash
THEME_DIR="/usr/share/sddm/themes/pixie"
SDDM_DIR="$HOME/.config/wallpapers/sddm"
WALLPAPER_DIR="$HOME/.config/wallpapers/normal"

if [ -z "$1" ]; then
    echo "Usage: sddm-wallpaper <path-to-image>"
    echo ""
    echo "SDDM wallpapers ($SDDM_DIR):"
    ls -1 "$SDDM_DIR" 2>/dev/null || echo "  (none)"
    echo ""
    echo "Desktop wallpapers ($WALLPAPER_DIR):"
    ls -1 "$WALLPAPER_DIR" 2>/dev/null || echo "  (none)"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File not found: $1"
    exit 1
fi

cp "$1" "$SDDM_DIR/$(basename "$1")"
echo "Saved to $SDDM_DIR/"

sudo cp "$1" "$THEME_DIR/assets/background.jpg"
if [ $? -eq 0 ]; then
    echo "SDDM wallpaper updated! Changes apply on next login."
else
    echo "Run manually: sudo cp \"$1\" $THEME_DIR/assets/background.jpg"
fi
SCRIPT
arch-chroot /mnt chmod +x /home/"$USERNAME"/.local/bin/sddm-wallpaper

# Nuit helpers (screenshots, wallpaper cycling, capture menu, screen recording)
cp "$REPO_DIR/configs/bin/"* /mnt/home/"$USERNAME"/.local/bin/
arch-chroot /mnt chmod +x /home/"$USERNAME"/.local/bin/nuit-*
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/nuit/backgrounds/default
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/nuit/current
cp "$REPO_DIR/configs/wallpapers/default/"* /mnt/home/"$USERNAME"/.config/nuit/backgrounds/default/

# Hyprland
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/hypr
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.Pictures/.Wallpapers
cp "$REPO_DIR/configs/hyprland/hyprland.conf" /mnt/home/"$USERNAME"/.config/hypr/hyprland.conf

# Hyprpaper (generated with the correct home directory)
cat > /mnt/home/"$USERNAME"/.config/hypr/hyprpaper.conf << EOF
ipc = on
splash = false
wallpaper {
    monitor =
    path = /home/$USERNAME/.config/nuit/backgrounds/default/brown_city_planet_w.jpg
    fit_mode = cover
}
EOF

# Quickshell
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/quickshell
cp -r "$REPO_DIR/configs/quickshell/"* /mnt/home/"$USERNAME"/.config/quickshell/

# Branding (shared logo referenced by the quickshell widgets)
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/Branding
cp -r "$REPO_DIR/configs/Branding/." /mnt/home/"$USERNAME"/.config/Branding/

# Neovim
arch-chroot /mnt mkdir -p /home/"$USERNAME"/.config/nvim
cp -r "$REPO_DIR/configs/nvim/"* /mnt/home/"$USERNAME"/.config/nvim/

# Zsh
arch-chroot /mnt chsh -s /bin/zsh "$USERNAME"

# Fix permissions
arch-chroot /mnt chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Nuit OS installation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Reboot and remove the install media."
echo "Login with the user you created."
