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
| ISO size | dev | `ls -lh out/*.iso` | ≤2.5GB, WebP <2MB each | TODO |
| SHA256 | dev | `sha256sum -c *.sha256` | OK | TODO |
| CI drift+build | clean checkout | `git clone --no-hardlinks … && just diff` + Actions | green | TODO |
| lynis | installed | `lynis audit system` | triaged, every warning fixed or reasoned | TODO |

## Paste outputs below (one section per row)
