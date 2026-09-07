#!/bin/bash
# Runs inside the airootfs chroot at ISO build time (archiso hook).
set -euo pipefail

# Live user (matches getty/sddm autologin in airootfs/etc). No password +
# NOPASSWD sudo is the standard live-CD model: the ISO is ephemeral and runs
# untrusted only in the VM/USB you boot it on.
if ! id nuitos &>/dev/null; then
  useradd -m -G wheel,audio,video,storage -s /bin/bash nuitos
fi
passwd -d nuitos
install -d /etc/sudoers.d
printf '%s\n' "nuitos ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nuitos
chmod 440 /etc/sudoers.d/nuitos

# yay-bin (prebuilt, ~5MB) — AUR helpers can't go in packages.x86_64.
# Upstream releases a GPG-signed source tarball; we pin the exact artifact
# SHA256 of the downloaded binary tarball so a tampered/moved asset fails the
# build loudly instead of shipping silently.
YAY_VER="13.0.1"
YAY_SHA256="1fdfcb5f7f387bc858d3a5754bdf4e4575bfbddac9560535a716d0ed7189c057"

install_yay() {
  local tarball="/tmp/yay.tar.gz"
  local dir="/tmp/yay_${YAY_VER}_x86_64"
  rm -rf "$tarball" "$dir"
  curl --fail --retry 3 --retry-all-errors --proto '=https' --tlsv1.2 -sSL \
    -o "$tarball" \
    "https://github.com/Jguer/yay/releases/download/v${YAY_VER}/yay_${YAY_VER}_x86_64.tar.gz"
  printf '%s  %s\n' "$YAY_SHA256" "$tarball" | sha256sum -c - >/dev/null
  tar -xzf "$tarball" -C /tmp
  if [ ! -x "$dir/yay" ]; then
    echo "error: extracted yay binary missing at $dir/yay" >&2
    exit 1
  fi
  install -Dm755 "$dir/yay" /usr/local/bin/yay
  rm -rf "$tarball" "$dir"
}

if ! command -v yay &>/dev/null; then
  install_yay
fi