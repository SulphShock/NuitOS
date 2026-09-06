
# 🌙 NuitOS

> Arch Linux + Hyprland. Lean. Minimal. Works.

A distro stripped of bloat. Just the essentials: tiling window manager, system topbar, app launcher, and nothing else. Build it, boot it, work.

---

## ✨ Features

- **Hyprland** — Tiling window manager configured for daily use
- **QuickShell topbar** — D-Bus integrated status bar with quick settings, calendar, notifications
- **Omarchy applauncher** — Walker-based fuzzy app search
- **Minimal packages** — Only what works. Choose your own terminal, shell, editor
- **CLI utilities** — Quick wrappers for common tasks
- **Reproducible builds** — Full ISO via `./build.sh`

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
./build.sh iso
```

Output: `NuitOS-x86_64.iso` (~2.2 GB) in `./out/`

### Install

1. Boot the ISO (UEFI or BIOS)
2. Run the installer
3. Reboot into Hyprland

Done. You have a working desktop.

---

## 📁 Repository Structure

```
NuitOS/
├── configs/              # Default application configs
│   ├── quickshell/       # Topbar (QuickShell/QML)
│   ├── hyprland/         # Window manager
│   ├── kitty/            # Terminal
│   └── ...
├── scripts/
│   ├── build.sh          # ISO builder
│   └── ...               # CLI utilities
├── pkgs/
│   ├── base.txt          # Core system packages
│   ├── gui.txt           # Optional GUI apps
│   └── dev.txt           # Development tools
└── airootfs/             # Files bundled into ISO
    └── etc/              # System configs
```

---

## 🎨 Customization

All configs are **editable before build** or **after install** in `~/.config/`.

### Change the terminal

Edit `pkgs/base.txt`:
```diff
- kitty
+ ghostty
```

Then rebuild the ISO.

### Change the shell

```diff
- zsh
+ bash
```

### Use your own topbar

Don't like the topbar? Disable it in `configs/hyprland/hyprland.conf`:
```bash
exec-once = # commented out
```

Use waybar, eww, or nothing.

---

## 🛠️ Building

### Full build commands

```bash
./build.sh iso              # Build ISO only
./build.sh iso test         # Build and test in QEMU
./build.sh clean            # Clean artifacts
./build.sh help             # Show all options
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
- Arch Linux base + linux-lts kernel
- Hyprland + Wayland stack
- systemd boot loader

**Graphics & Audio:**
- Intel/AMD/NVIDIA drivers (auto-selected)
- PipeWire (sound)
- Wayland support libraries

**Essentials:**
- `kitty` (terminal)
- `zsh` (shell)
- `vim` (editor)
- NetworkManager (networking)
- `git`

**Fonts:**
- JetBrains Mono Nerd Font
- Inter

**Nothing else.** Want Firefox? Install it. Docker? Install it. The ISO doesn't ship bloat.

---

## ⌨️ Keybinds

Hyprland defaults:

| Key | Action |
|-----|--------|
| <kbd>Super</kbd> + <kbd>Return</kbd> | Open terminal |
| <kbd>Super</kbd> + <kbd>Space</kbd> | App launcher |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>F</kbd> | Fullscreen |
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch workspace |
| <kbd>Super</kbd> + Click/Drag | Move/resize window |

Full config: `configs/hyprland/hyprland.conf`

---

## 🖥️ System Info

After boot:

```bash
$ neofetch
```

- **OS:** NuitOS (Arch Linux)
- **WM:** Hyprland
- **Shell:** zsh
- **Terminal:** kitty
- **Font:** JetBrains Mono Nerd

---

## 🤝 Contributing

Issues, feature requests, and PRs welcome.

**Keep it lean.** NuitOS is intentionally minimal. Big new features go in userland, not the ISO.

**Keep it honest.** If something's broken, say so. If it's a workaround, document why.

---

## 📜 License

MIT. See `LICENSE`.

---

## 📚 References

- [Arch Linux](https://archlinux.org)
- [Hyprland Docs](https://hyprland.org)
- [QuickShell](https://github.com/outfoxxed/quickshell)
- [Walker](https://github.com/abenz1267/walker)

---

<p align="center">
  <strong>NuitOS</strong> — Hyprland + Arch. Built lean. Built simple. <br>
  <a href="https://github.com/SulphShock/NuitOS">View on GitHub</a>
</p>
