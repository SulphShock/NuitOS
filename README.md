
# 🌙 Nuit OS

> Arch Linux + Hyprland. Gruvbox-dark. Ready to work.

A bootable, day-one desktop: tiling window manager, system topbar, app launcher, gruvbox-dark login theme, and a curated set of daily-use apps. Build it, boot it, work.

---

## ✨ Features

- **Hyprland** — Tiling window manager configured for daily use
- **QuickShell topbar** — D-Bus integrated status bar with quick settings, calendar, notifications
- **App launcher** — in-shell Activities grid (Super+Space)
- **Gruvbox-dark login** — `gruvbox-minimal-sddm` theme matching the desktop palette
- **Curated packages** — Daily-use apps preinstalled (terminal, browser, editor, media); extend via `yay`
- **CLI utilities** — Quick wrappers for common tasks
- **Reproducible builds** — Pure archiso profile in `iso/`

---

## 🚀 Quick Start

### Prerequisites

- Arch Linux with `archiso` and `base-devel` installed
- ~15 GB free disk space (build tree + output ISO)

### Build the ISO

```bash
git clone https://github.com/SulphShock/NuitOS.git
cd NuitOS
sudo mkarchiso -v -w /tmp/nuitos-build -o ./out ./iso
```

Output: `NuitOS-YYYY.MM.DD-x86_64.iso` (~3 GB) in `./out/`

### Run

1. Flash the ISO to a USB stick (UEFI only — the installer uses systemd-boot)
2. Boot the live session into Hyprland

Done. You have a working desktop.

### Install to disk

> ⚠️ **The installer permanently erases the target disk.** There is no undo — back up first.

From the live session, run:

```bash
nuit-installer
```

It asks for disk, filesystem (ext4/btrfs), swap, LUKS2 encryption, locale/keymap/timezone, user, hostname, and whether to enable **autologin** (default: off — you log in with your password at the gruvbox SDDM screen). Use `nuit-installer --dry-run` to preview the plan without touching the disk.

---

## 📁 Repository Structure

```
NuitOS/
├── configs/              # Default application configs
│   ├── quickshell/       # Topbar (QuickShell/QML)
│   ├── hyprland/         # Window manager
│   ├── ghostty/          # Terminal
│   └── ...
└── iso/                  # archiso profile (pure ISO)
    ├── profiledef.sh     # ISO definition (required by archiso)
    ├── packages.x86_64   # Packages bundled into ISO
    ├── pacman.conf       # Pacman config for build
    └── airootfs/         # Files bundled into ISO
        ├── etc/skel/     # Default user dotfiles (hypr, quickshell, nvim, …)
        ├── usr/local/bin/# nuit-installer + nuit-* helpers
        └── usr/share/    # backgrounds, plymouth + SDDM themes
```

---

## 🎨 Customization

All configs are **editable before build** or **after install** in `~/.config/`.

### Change the terminal

Edit `iso/packages.x86_64`:
```diff
- ghostty
+ alacritty
```

Then rebuild the ISO.

### Change the shell

NuitOS ships **bash** by default. To use another shell, add it to `iso/packages.x86_64` and
point the `-s` flag in `iso/airootfs/root/customize_airootfs.sh` at it:

```diff
- useradd -m -G wheel,audio,video,storage -s /bin/bash nuitos
+ useradd -m -G wheel,audio,video,storage -s /bin/fish nuitos
```

### Use your own topbar

Don't like the topbar? Disable it in `configs/hyprland/hyprland.conf`:
```bash
exec-once = # commented out
```

Use waybar, eww, or nothing.

---

## 🛠️ Building

```bash
sudo mkarchiso -v -w /tmp/nuitos-build -o ./out ./iso
```

### Requirements for building

- `archiso` (provides `mkarchiso`)
- `git`
- Root/sudo access (mkarchiso needs it)
- Fast internet (downloads ~500 MB of packages)

### Build time

~3-5 minutes on a decent machine. Varies with disk speed and internet.

---

## 📦 What's Included (Base)

**Core:**
- Arch Linux base + `linux` kernel
- Hyprland + Wayland stack
- systemd boot loader

**Graphics & Audio:**
- Intel/AMD microcode + `linux-firmware`
- PipeWire (sound)
- Wayland support libraries

**Essentials:**
- `ghostty` (terminal)
- `bash` (shell)
- `neovim` + `vim` (editors)
- `thunar` (file manager)
- NetworkManager (networking)
- `git`

**Fonts:**
- JetBrains Mono Nerd Font
- Fira Code, Fantasque, Cascadia (with `ttf-jetbrains-mono` fallback)

**Also ships:** `firefox`, `docker` + `docker-compose`, `vlc`, `gimp`, `obsidian`, `discord`, `file-roller` — a bootable, day-one desktop. Add anything else with AUR via `yay`.

---

## ⌨️ Keybinds

Hyprland defaults:

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Return</kbd> | Open terminal (ghostty) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | App launcher (Activities grid) |
| <kbd>Super</kbd> + <kbd>C</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>V</kbd> | Toggle floating |
| <kbd>Super</kbd> + <kbd>P</kbd> | Pseudo-tile |
| <kbd>Super</kbd> + <kbd>J</kbd> | Toggle split |
| <kbd>Super</kbd> + <kbd>1-0</kbd> | Switch workspace |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1-0</kbd> | Move window to workspace |
| <kbd>Super</kbd> + <kbd>S</kbd> | Quick Settings |
| <kbd>Super</kbd> + <kbd>T</kbd> | Calendar |
| <kbd>Super</kbd> + <kbd>A</kbd> | Activities (app grid) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Settings panel |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Random wallpaper |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Open file manager (thunar) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Open browser (firefox) |
| <kbd>PrtSc</kbd> / <kbd>Shift</kbd>+<kbd>PrtSc</kbd> | Screenshot region → clipboard / file |
| <kbd>Super</kbd> + Click/Drag | Move/resize window |

Full config: `configs/hyprland/hyprland.conf`

---

## 🖥️ System Info

After boot:

```bash
$ fastfetch
```

- **OS:** Nuit OS (Arch Linux)
- **WM:** Hyprland
- **Shell:** bash
- **Terminal:** ghostty
- **Font:** JetBrains Mono Nerd

---

## 🤝 Contributing

Issues, feature requests, and PRs welcome.

**Keep it coherent.** Gruvbox-dark look, working defaults, no dead code. Big new features go in userland, not the ISO.

**Keep it honest.** If something's broken, say so. If it's a workaround, document why.

---

## 📜 License

MIT. See `LICENSE`.

---

## 📚 References

- [Arch Linux](https://archlinux.org)
- [Hyprland Docs](https://hyprland.org)
- [QuickShell](https://github.com/outfoxxed/quickshell)
- [gruvbox-minimal-sddm](https://github.com/scientiac/gruvbox-minimal-sddm) (MIT login theme, vendored + tuned)

---

<p align="center">
  <strong>Nuit OS</strong> — Hyprland + Arch. Gruvbox-dark. Built to work. <br>
  <a href="https://github.com/SulphShock/NuitOS">View on GitHub</a>
</p>
