
# 🌙 Nuit OS

> Arch Linux + Hyprland. Lean. Minimal. Works.

A distro stripped to the essentials: tiling window manager, system topbar, app launcher, and a small curated set of daily-use apps. Build it, boot it, work.

---

## ✨ Features

- **Hyprland** — Tiling window manager configured for daily use
- **QuickShell topbar** — D-Bus integrated status bar with quick settings, calendar, notifications
- **App launcher** — `wofi` for fuzzy app search, plus QuickShell's in-shell Activities grid
- **Minimal packages** — Only what works. Choose your own terminal, shell, editor
- **CLI utilities** — Quick wrappers for common tasks
- **Reproducible builds** — Pure archiso profile in `iso/`

---

## 🚀 Quick Start

### Prerequisites

- Arch Linux (or any rolling release with `archiso`)
- `base-devel` installed
- ~5 GB free disk space

### Build the ISO

```bash
git clone https://github.com/SulphShock/NuitOS.git
cd NuitOS
sudo mkarchiso -v -w /tmp/nuitos-build -o ./out ./iso
```

Output: `NuitOS-YYYY.MM.DD-x86_64.iso` (~3 GB) in `./out/`

### Run

1. Flash the ISO (UEFI or BIOS)
2. Boot the live session into Hyprland

Done. You have a working desktop.

---

## 📁 Repository Structure

```
NuitOS/
├── configs/              # Default application configs
│   ├── quickshell/       # Topbar (QuickShell/QML)
│   ├── hyprland/         # Window manager
│   ├── ghostty/          # Terminal
│   └── ...
├── pkgs/
│   ├── core.txt          # Package list
│   └── ...
└── iso/                  # archiso profile (pure ISO)
    ├── profiledef.sh     # ISO definition (required by archiso)
    ├── packages.x86_64   # Packages bundled into ISO
    ├── pacman.conf       # Pacman config for build
    ├── grub/             # Bootloader config
    └── airootfs/         # Files bundled into ISO
        └── etc/          # System configs + skel
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
- Intel/AMD/NVIDIA drivers (auto-selected)
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
| <kbd>Super</kbd> + <kbd>Space</kbd> | App launcher (wofi) |
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
$ neofetch
```

- **OS:** Nuit OS (Arch Linux)
- **WM:** Hyprland
- **Shell:** bash
- **Terminal:** ghostty
- **Font:** JetBrains Mono Nerd

---

## 🤝 Contributing

Issues, feature requests, and PRs welcome.

**Keep it lean.** Nuit OS is intentionally minimal. Big new features go in userland, not the ISO.

**Keep it honest.** If something's broken, say so. If it's a workaround, document why.

---

## 📜 License

MIT. See `LICENSE`.

---

## 📚 References

- [Arch Linux](https://archlinux.org)
- [Hyprland Docs](https://hyprland.org)
- [QuickShell](https://github.com/outfoxxed/quickshell)
- [wofi](https://sr.ht/~scooter/wofi/)

---

<p align="center">
  <strong>Nuit OS</strong> — Hyprland + Arch. Built lean. Built simple. <br>
  <a href="https://github.com/SulphShock/NuitOS">View on GitHub</a>
</p>
