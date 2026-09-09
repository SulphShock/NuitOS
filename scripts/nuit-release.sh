#!/bin/bash
# nuit-release — build the NuitOS ISO and (optionally) flash it to a USB stick.
#
# Usage:
#   sudo ./scripts/nuit-release.sh                # build only
#   sudo ./scripts/nuit-release.sh /dev/sdX       # build + flash to /dev/sdX
#   sudo ./scripts/nuit-release.sh --flash-only   # flash the existing built ISO
#
# SAFETY: when flashing, the target device is WIPED. The script refuses:
#   - missing devices, loop/NVMe (expects a full block device)
#   - a device mounted anywhere
#   - a device that is the running root or contains the OS
#   - a device larger than 128 GiB (sanity guard against nvme/sata disks)
# The ISO path is written under /run/media unless --flash-only is used.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_DIR="$REPO/out"
WORK="${NUIT_WORK:-/tmp/nuitos-build}"

BUILD_DIR() { [ "$1" = "full" ] && echo "building full ISO" || echo "flash-only mode"; }

RED=$'\e[31m'; YEL=$'\e[33m'; GRN=$'\e[32m'; DIM=$'\e[2m'; RST=$'\e[0m'
note() { printf '%s[build]%s %s\n' "${DIM}" "${RST}" "$*"; }
warn() { printf '%s[warn]%s %s\n' "${YEL}" "${RST}" "$*"; }
die()  { printf '%s[error]%s %s\n' "${RED}" "${RST}" "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run with sudo (mkarchiso, dd, mount/unmount all need root)"
command -v mkarchiso >/dev/null 2>&1 || die "mkarchiso not found — install archiso (pacman -S archiso)"

if [ "${1:-}" = "--flash-only" ]; then
    MODE="flash-only"
    DEV="${2:-}"
else
    MODE="full"
    DEV="${1:-}"
fi

# ---------------------------------------------------------------- build ---
if [ "$MODE" = "full" ]; then
    # ---- wallpapers: configs/wallpapers/default is the single source of truth.
    # The two ISO spots (live /usr/share/backgrounds + skel ~/.config/nuit/
    # backgrounds) are mirrors — synced here so nobody triple-copies by hand.
    # (They stay committed in-tree so a bare `mkarchiso ./iso` still works.)
    note "syncing wallpapers (canonical: configs/wallpapers/default)"
    WALL_SRC="$REPO/configs/wallpapers/default"
    [ -d "$WALL_SRC" ] || die "missing canonical wallpapers: $WALL_SRC"
    [ -n "$(ls -A "$WALL_SRC" 2>/dev/null)" ] || die "no wallpapers in $WALL_SRC"
    for dest in "$REPO/iso/airootfs/usr/share/backgrounds" \
                "$REPO/iso/airootfs/etc/skel/.config/nuit/backgrounds"; do
        mkdir -p "$dest"
        for f in "$dest"/*; do
            [ -e "$f" ] || continue
            [ -e "$WALL_SRC/$(basename "$f")" ] || { note "dropping stale wallpaper: $f"; rm -f "$f"; }
        done
        cp -f "$WALL_SRC"/* "$dest"/
    done

    # ---- drift guard: helper/config copies must match their canonical source.
    # Edit the canonical file, never the copy — the build refuses on mismatch.
    drift=0
    check_same() {
        cmp -s "$1" "$2" || { warn "drift: $1 != $2"; drift=1; }
    }
    check_same "$REPO/configs/bin/nuit-capture-menu"  "$REPO/iso/airootfs/usr/local/bin/nuit-capture-menu"
    check_same "$REPO/configs/bin/nuit-screenrecord"  "$REPO/iso/airootfs/usr/local/bin/nuit-screenrecord"
    check_same "$REPO/configs/bin/nuit-screenshot"    "$REPO/iso/airootfs/usr/local/bin/nuit-screenshot"
    check_same "$REPO/scripts/nuit-random-wallpaper.sh" "$REPO/iso/airootfs/usr/local/bin/nuit-random-wallpaper"
    for t in nuit-theme-bg-set nuit-theme-bg-next nuit-theme-bg-folder nuit-theme-bg-current; do
        check_same "$REPO/scripts/$t" "$REPO/iso/airootfs/usr/local/bin/$t"
    done
    check_same "$REPO/configs/hyprland/hyprland.conf" "$REPO/iso/airootfs/etc/skel/.config/hypr/hyprland.conf"
    for d in quickshell ghostty nvim fastfetch Branding; do
        diff -rq "$REPO/configs/$d" "$REPO/iso/airootfs/etc/skel/.config/$d" >/dev/null 2>&1 \
            || { warn "drift: configs/$d != skel .config/$d"; drift=1; }
    done
    [ "$drift" -eq 0 ] || die "config drift detected — sync the canonical sources and re-run"
    note "drift guard clean"

    note "removing stale build tree: $WORK"
    rm -rf "$WORK"
    note "removing stale output: $ISO_DIR"
    rm -rf "$ISO_DIR"
    mkdir -p "$ISO_DIR"

    note "building ISO (mkarchiso on $REPO/iso)"
    mkarchiso -v -w "$WORK" -o "$ISO_DIR" "$REPO/iso"
    note "build finished"
fi

ISO="$(ls "$ISO_DIR"/*.iso 2>/dev/null | sort -r | head -n1 || true)"
[ -n "$ISO" ] || die "no ISO found in $ISO_DIR"
note "ISO: $ISO"
ls -lh "$ISO"

if [ -z "$DEV" ]; then
    echo
    note "done. flash it later with: sudo $0 <usb-device>"
    exit 0
fi

# --------------------------------------------------------------- flash ---
[ -b "$DEV" ] || die "not a block device: $DEV"
case "$DEV" in
    /dev/nvme*|/dev/loop*|/dev/mapper/*) die "refusing loop/nvme/mapper device: $DEV" ;;
esac

# Must be a full disk, not a partition.
disk="${DEV#/dev/}"
lsblk -rno TYPE "/dev/$disk" 2>/dev/null | grep -qx disk || die "$DEV is not a whole disk"

# Sanity: not mounted anywhere.
mnt="$(lsblk -nro MOUNTPOINT "/dev/$disk" 2>/dev/null | grep -v '^$' || true)"
[ -z "$mnt" ] || die "$DEV is mounted at: $mnt"

# Sanity: not the running root/boot/usr device.
if grep -q "$DEV" /proc/mounts; then die "$DEV appears in /proc/mounts"; fi
ROOTDEV="$(findmnt -no SOURCE / 2>/dev/null || true)"
case "$ROOTDEV" in
    /dev/sd[a-z]*) [ "$ROOTDEV" = "$DEV" ] && die "$DEV is the running root device!" ;;
    *mapper*) real="$(readlink -f "$ROOTDEV" 2>/dev/null || true)"; [ "$real" = "$DEV" ] && die "$DEV is the running root device!" ;;
esac

SIZE_BYTES="$(lsblk -bndo SIZE "/dev/$disk" 2>/dev/null || echo 0)"
SIZE_G=$(( SIZE_BYTES / 1024 / 1024 / 1024 ))
[ "$SIZE_G" -le 128 ] || die "refusing device larger than 128 GiB ($SIZE_G GiB) — this looks like a hard disk"

# Checksum the ISO first (so a bad flash isn't blamed on a bad build).
md5sum "$ISO"

ISO_BYTES="$(stat -c%s "$ISO")"
[ "$ISO_BYTES" -lt "$SIZE_BYTES" ] || die "ISO ($ISO_BYTES bytes) does not fit on $DEV ($SIZE_BYTES bytes)"

echo
warn "WILL WIPE $DEV (${SIZE_G} GiB) and write:"
ls -lh "$ISO"
printf 'Type the device path to confirm: '
read -r confirm
[ "$confirm" = "$DEV" ] || die "confirmation mismatch — aborting"

note "flashing — do not unplug the stick"
dd if="$ISO" of="$DEV" bs=4M status=progress conv=fsync oflag=direct
sync
note "flash complete. Eject with: udisksctl unmount -b $DEV   (then physically remove)"