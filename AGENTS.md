# AGENTS.md — NuitOS

## Project purpose
NuitOS is an Arch Linux + Hyprland desktop distribution. It ships a bootable ISO built with archiso, plus canonical application configs that get deployed to `~/.config/` on install. Gruvbox-dark theme throughout.

## Ground truth (do not contradict)
- **Shell:** zsh (installed system default)
- **Terminal:** ghostty (NOT kitty)
- **Topbar:** QuickShell/QML (NOT waybar)
- **Launcher:** in-shell AppMenu via QuickShell (Super+Space), NOT wofi or walker
- **License:** MIT (see `LICENSE`)
- **Package list:** `iso/packages.x86_64` is canonical. There is NO `pkgs/` directory.
- **Build script:** `scripts/nuit-release.sh` is the reference bash style.

## Directory layout
```
NuitOS/
├── AGENTS.md                 # This file
├── CHANGELOG.md              # Release changelog
├── CONTRIBUTING.md           # Contribution rules
├── LICENSE                   # MIT license
├── MAINTAINERS.md            # Release checklist, maintainer list
├── README.md                 # User-facing docs
├── TESTING.md                # Evidence bundle (no done without output)
├── configs/                  # Canonical application configs (edit these)
│   ├── bin/                  # Helper scripts shipped as commands
│   ├── Branding/             # Logo assets
│   ├── fastfetch/            # Fastfetch config
│   ├── ghostty/              # Terminal config
│   ├── hypridle/             # Idle manager config
│   ├── hyprland/             # Hyprland WM (split: env/appearance/rules/autostart/bindings)
│   ├── hyprlock/             # Lock screen config
│   ├── hyprpaper/            # Wallpaper daemon config
│   ├── nvim/                 # Neovim config
│   ├── quickshell/           # Topbar + widgets (QML)
│   └── wallpapers/default/   # Canonical wallpaper set (WebP)
├── iso/                      # archiso profile
│   ├── airootfs/             # Files bundled into ISO
│   ├── efiboot/              # UEFI systemd-boot entries
│   ├── packages.x86_64       # Package list
│   ├── pacman.conf           # Pacman config for build
│   ├── profiledef.sh         # ISO definition (required by archiso)
│   └── syslinux/             # BIOS syslinux config
├── justfile                  # Task runner (diff/deploy/install)
├── scripts/                  # Build + utility scripts
│   ├── nuit-release.sh       # ISO build + flash
│   ├── nuit-installer        # Disk installer (archiso chroot)
│   ├── nuit-aur-install      # AUR bootstrap (runs on first login)
│   └── nuit-theme-bg-*       # Wallpaper cycling scripts
└── .github/
    └── workflows/            # CI: build, drift guard, release
```

## Build command
```bash
sudo ./scripts/nuit-release.sh          # build ISO
sudo ./scripts/nuit-release.sh /dev/sdX # build + flash
```
Output: `out/NuitOS-YYYY.MM.DD-x86_64.iso`

## Style rules
- Bash: `set -euo pipefail`, `note/warn/die` helpers, ANSI colors (see `scripts/nuit-release.sh`).
- One logical change per commit, imperative subject (`feat:`, `fix:`, `docs:`, `chore:`).
- `configs/` is canonical; never edit skel copies directly.
- `--dry-run` paths stay read-only.
- Never rewrite git history or force-push.
- Never touch `iso/airootfs` unless a phase explicitly says to.

## Verification checklist
- `bash -n` on all shell scripts before commit.
- `shellcheck` on all shell scripts.
- Drift guard: `just diff` must pass (configs ↔ skel).
- YAML: all workflow files must parse with `python3 -c "import yaml; yaml.safe_load(open(f))"`.
- README: every path mentioned must exist in the repo.

## Notes for agents
- If a phase is blocked, STOP and ask — do not guess, do not skip ahead.
- Prefer the least-work / laziest way that satisfies the requirement.
- Phase 7 (website sync) requires the Cloudflare Worker source path — it is NOT in this repo.
