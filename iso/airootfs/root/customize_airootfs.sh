#!/bin/bash
# Runs inside the airootfs chroot at ISO build time (archiso hook).
set -e

# Live user (matches getty/sddm autologin in airootfs/etc)
if ! id nuitos &>/dev/null; then
  useradd -m -G wheel,audio,video,storage -s /bin/zsh nuitos
fi
passwd -d nuitos
echo "nuitos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nuitos
chmod 440 /etc/sudoers.d/nuitos

# yay-bin (prebuilt, ~5MB) — AUR helpers can't go in packages.x86_64.
YAY_VER="13.0.1"
curl -L -o /tmp/yay.tar.gz \
  "https://github.com/Jguer/yay/releases/download/v${YAY_VER}/yay_${YAY_VER}_x86_64.tar.gz"
tar -xzf /tmp/yay.tar.gz -C /tmp
install -Dm755 "/tmp/yay_${YAY_VER}_x86_64/yay" /usr/local/bin/yay
rm -rf /tmp/yay.tar.gz "/tmp/yay_${YAY_VER}_x86_64"
yay --version
