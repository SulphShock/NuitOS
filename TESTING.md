# NuitOS v1.0 TESTING — evidence bundle (no "done" without output)

Fill every row with pasted command output. Blank = not done.

## Matrix

| Check | Env | Command | Expected | Result |
|---|---|---|---|---|
| B1 live tools | live ISO | `for c in sgdisk jq pacstrap arch-chroot genfstab bootctl cryptsetup partprobe blkid findmnt mount umount mkfs.fat mkfs.btrfs mkfs.ext4 mkswap localectl timedatectl hwclock systemctl gum; do command -v $c >/dev/null || echo MISSING:$c; done` | no MISSING lines | TODO |
| B2 args preserved | live ISO | `nuit-installer --dry-run` as `nuitos` + `nuit-installer --unattended FILE --dry-run` | plan correct, no arg loss | TODO |
| B3 dry-run no prompt | live ISO | `nuit-installer --dry-run` | no GO prompt, exit 0, prints plan | TODO |
| B4 UEFI gate honest | live ISO BIOS boot | `nuit-installer --dry-run` | prints SKIP/BIOS, no lie | TODO |
| B5 encrypted swap | installed (LUKS) | `swapon --show` | `/dev/mapper/cryptswap` or swapfile in cryptroot | TODO |
| B6 shadow perms | live + installed | `ls -l /etc/shadow` | `0640 root:shadow` both | TODO |
| B7 browser bind | installed | `Super+Shift+B` | firefox opens | TODO |
| Boot → desktop | live ISO UEFI | boot, `qs list`, `systemctl --user is-active hyprpaper` | qs running, hyprpaper active | TODO |
| Install e2e | VM UEFI | `nuit-installer`, reboot → slick-greeter → login → desktop | working desktop | TODO |
| BIOS boot scope | n/a | — | `BIOS boot: unsupported (UEFI-only, systemd-boot)` | SCOPE |
| Real hardware | spare disk | install + reboot + desktop | `PASS (date+machine) | out of scope for v1.0` | TODO |
| ISO size | dev | `ls -lh out/*.iso` | ≤3.5GB, WebP <2MB each | TODO |
| SHA256 | dev | `sha256sum -c out/NuitOS-*.iso.sha256` | OK | TODO |
| CI drift+build | clean checkout | `git clone --no-hardlinks … && just diff` + Actions | green | TODO |
| lynis | installed | `lynis audit system` | triaged, every warning fixed or reasoned | TODO |

## Paste outputs below (one section per row)

### 2026-09-12 dev-box evidence (branch sync/live-to-repo, no sudo / no live ISO)

- Package hygiene: `grep -E '^[^#[:blank:]]+[[:blank:]]+#' iso/packages.x86_64 iso/airootfs/usr/local/share/nuit/pkgs-disk.txt` → no hits (HYGIENE-OK).
- Skel drift: split-hypr 7 files + shader + quickshell tree all `cmp/diff -rq` clean (SKEL-DRIFT-CLEAN).
- Wallpapers: 5× WebP, 166K–616K each, dir total 1.9M (was 39M). Originals in `~/nuitos-wallpapers-originals/` (local, uncommitted).
- `bash -n` installer + release script: both OK.
- B6 code: `profiledef.sh` now `0640 etc/shadow etc/gshadow` + `0644 passwd/group` with fixed indices. Live+installed `ls -l` rows stay TODO for live-ISO boot.
- B1-B5/B7 rows stay TODO for live-ISO boot (needs sudo + VM). B7 code path fixed via bindings unify (ghostty+firefox).
- Task 0.3 login as `nuitos-test`: BLOCKED — no sudo in this shell (`useradd` refused). File-level smoke green (TimeHub present, Planova gone, split hypr 9/9, zero `/home/freeman` refs, drift clean). Full login must run on live ISO / sudo box.
- Real hardware: out of scope for v1.0 (VM UEFI install is the gate).

### 2026-09-13 keybind-restore evidence (file-level, no sudo / no rebuild yet)

- Keybinds: old monolith set restored into `bindings.conf` + `source=` wired in `hyprland.conf` + skel mirrors + `bindings.lua` synced (all `cmp` clean). Every documented key verified present by grep: C/V/B/F1/Ctrl+C/Shift+Space/0-10.
- Drift: full `nuit-release.sh` guard replicated file-by-file → fail=0. Hygiene clean. machine-id empty. Wallpapers synced (5x WebP).
- Packages: 18 gaps closed in `iso/packages.x86_64` (mesa, vulkan-virtio, Qt stack, upower, Adwaita, kvantum, hyprpicker, procps-ng, hyprshade, cliphist, iproute2, tesseract-data-eng, file, ucode x2, plymouth). Polkit path + theme-bg-setter path bugs fixed (mirrors sync, `bash -n` clean).
- Bootloaders: `console=ttyS0,115200 console=tty1` on all 4 entries (UEFI x2, BIOS x2).
- Gates: 3.5GB in MAINTAINERS + TESTING. YAML parses. `just` not installed here — justfile reviewed by eye only.
- BLOCKED: ISO rebuild needs sudo (`sudo ./scripts/nuit-release.sh`) — no passwordless sudo in this shell. B1-B9 live rows stay TODO until rebuilt ISO boots in VM.
