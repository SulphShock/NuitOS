
# 🌙 Nuit OS

> Arch Linux + Hyprland. Gruvbox-dark. Ready to work.

A bootable, day-one desktop: tiling window manager, system topbar, app launcher, gruvbox-dark login theme, and a curated set of daily-use apps. Build it, boot it, work.

---

## ✨ Features

- **Hyprland** — Tiling window manager configured for daily use
- **QuickShell topbar** — D-Bus integrated status bar with quick settings, calendar, notifications
- **App launcher** — in-shell Activities grid (Super+Space)
- **Gruvbox-dark login** — LightDM + slick-greeter in gruvbox-dark, matching the desktop
- **Curated packages** — Daily-use apps preinstalled (terminal, browser, editor, media); extend via `yay`
- **CLI utilities** — Quick wrappers for common tasks
- **Reproducible builds** — Pure archiso profile in `iso/`

---

## 🚀 Quick Start

### 🐣 New to Linux? Start here

You don't need Linux installed to try NuitOS — but you do need a USB stick (4 GB or larger) and about 30 minutes.

1. **Download the ISO** from the [Releases page](https://github.com/SulphShock/NuitOS/releases) (the file ends in `.iso`, ~3 GB).
2. **Flash it to the USB stick** with [balenaEtcher](https://etcher.balena.io/) (Windows/macOS/Linux): open Etcher → *Flash from file* → pick the ISO → *Select target* → pick your USB stick → *Flash!*. This erases the stick.
3. **Turn off Secure Boot** in your BIOS/UEFI settings (NuitOS, like stock Arch, won't boot with it on). Common keys to enter setup: <kbd>Del</kbd>, <kbd>F2</kbd>, <kbd>F10</kbd>, <kbd>Esc</kbd>.
4. **Boot from the stick**: plug it in, restart, and press your boot-menu key (<kbd>F12</kbd>, <kbd>F8</kbd>, or <kbd>Esc</kbd> on most machines) → select the USB device.
5. **What you'll see**: straight into an empty desktop with a top bar and a wallpaper — no login screen when trying the OS. Nothing is broken — it's a tiling desktop, and it's waiting for you:
   - <kbd>Super</kbd> (= Windows key) + <kbd>Space</kbd> → app grid (find the **Nuit OS Installer** here)
   - <kbd>Super</kbd> + <kbd>Return</kbd> → terminal
   - <kbd>Super</kbd> + <kbd>F1</kbd> → full key list
6. **To install it for real**, open the app grid and launch **Nuit OS Installer**. It asks plain questions, shows a summary, and never touches anything before you type GO. (It will erase the disk you point it at — back up first.)

Nothing you do in the live session touches your computer until the installer runs.

### Prerequisites (building the ISO yourself)

- Arch Linux with `archiso` and `base-devel` installed
- ~15 GB free disk space (build tree + output ISO)

### Build the ISO

```bash
git clone https://github.com/SulphShock/NuitOS.git
cd NuitOS
sudo ./scripts/nuit-release.sh
```

Output: `NuitOS-YYYY.MM.DD-x86_64.iso` in `./out/`

Verify your download before flashing:

```bash
sha256sum -c NuitOS-*.iso.sha256
```

### Run

1. Flash the ISO to a USB stick (UEFI-only distro — the installer uses systemd-boot and refuses BIOS; the live session boots UEFI. `BIOS boot: unsupported.`)
2. Boot the live session into Hyprland

Done. You have a working desktop.

### Install to disk

> ⚠️ **The installer permanently erases the target disk.** There is no undo — back up first.

From the live session, run:

```bash
nuit-installer
```

It asks for disk, filesystem (ext4/btrfs), swap, LUKS2 encryption, locale/keymap/timezone, user, hostname, and whether to enable **autologin** (default: off — you log in with your password at the gruvbox slick-greeter screen). Use `nuit-installer --dry-run` to preview the plan without touching the disk (read-only, never prompts GO, exit 0).

LUKS installs encrypt swap too (swapfile inside the encrypted root — no plain-text swap). Note: encrypted swap means no hibernation/suspend-to-disk by design; suspend-to-RAM still works.

---

## 📁 Repository Structure

```
NuitOS/
├── configs/              # Canonical application configs (edit these)
│   ├── quickshell/       # Topbar (QuickShell/QML)
│   ├── hyprland/         # Window manager
│   ├── ghostty/          # Terminal
│   └── ...
├── iso/                  # archiso profile (pure ISO)
│   ├── profiledef.sh     # ISO definition (required by archiso)
│   ├── packages.x86_64   # Live-session packages
│   ├── pacman.conf       # Pacman config for build
│   └── airootfs/         # Files bundled into ISO
│       ├── etc/skel/     # Default user dotfiles (mirrors of configs/, checked by nuit-release.sh)
│       ├── usr/local/bin/# nuit-installer + nuit-* helpers
│       └── usr/share/    # backgrounds, plymouth theme, greeter brand
├── scripts/              # nuit-release.sh (guarded build + optional flash) + helpers
├── out/                  # Build output ISO (gitignored)
└── work/                 # Build tree (gitignored, needs sudo to clean)
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

### 💤 Idle (hypridle)

Leave the machine alone and it dims itself: after 5 idle minutes a slow
fade drifts over the screen, after 10 it locks, after 15 the display sleeps,
after 30 the machine suspends. Any key or mouse wiggle resets the timers.

- **Config lives in two places (kept identical):**
  `configs/hypridle/hypridle.conf` (edit this one) and
  `~/.config/hypr/hypridle.conf` (the live copy on the ISO/installed system).
- **Change the idle timeout:** edit the first `timeout = 300` (seconds —
  `600` = 10 min) in `configs/hypridle/hypridle.conf`, then rebuild.
- **The animation itself** is `nuit-idle-animation` (`configs/bin/`) talking
  to `configs/quickshell/widgets/IdleOverlay.qml` via
  `qs ipc call gsb setIdle true|false`.
- **Disable a stage:** comment out its whole `listener { ... }` block. To
  turn idle handling off entirely, comment out `exec-once = hypridle` in
  `configs/hyprland/hyprland.conf`.
- **Add a stage:** copy a `listener` block and change the timeout + command
  (keep timeouts in ascending order). Each block documents its own knob.

### 🌙 Night Light (hyprshade)

Warms the screen after dark so late sessions are easier on the eyes
(gentle 4500K screen shader via `hyprshade on nuit-night-light`; `hyprshade off` reverts —
gammastep can't work here, Hyprland has no gamma-control protocol).

- **Toggle:** top bar → Quick Settings → Night Light, or
  `qs ipc call gsb toggleNightLight`.
- **Shader:** `configs/hyprland/shaders/nuit-night-light.glsl` (edit this one).
  Tune the temperature there; lower (e.g. 3500K) for a warmer screen.
- **Legacy:** `configs/gammastep/config.ini` is kept for reference only and is
  not launched by the session.

---

## 🛠️ Building

```bash
sudo ./scripts/nuit-release.sh
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
- JetBrains Mono Nerd Font (terminal + UI face — the only coding font shipped)

**Also ships:** `gimp`, `file-roller` — a bootable, day-one desktop.
- Live session: `firefox` (browser), `mpv` (media). No display manager live — tty1 autologin straight into Hyprland for user `nuitos` only.
- Installed disk: `firefox` (browser), `LightDM + slick-greeter` (login), `mpv` (media).
- Both: `zed`, `obsidian`, `nodejs` + `npm` (nvim LSP/Treesitter need them), `socat` + `yt-dlp` (QuickShell music needs them). Notes, chat, and anything else via `yay`.

**Developers:** the ISO ships `base-devel` (C toolchain, includes gcc/make/pkgconf) plus `nodejs`/`npm` — install `cmake` post-setup with `yay -S cmake` if your editor plugins need it.

**Editor:** neovim uses gruvbox-dark (hard) with `Super+Shift+F` for files (`Space f` works everywhere as fallback), arrow keys in the tree (`n` rename, `a` new, `dd` delete, `r` refresh). Treesitter parsers install on demand with `:TSInstallNuit`. LSP starts only for servers you have installed — silence there means "not installed," not "broken".

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
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> | Open file manager (nautilus) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Open browser (firefox) |
| <kbd>PrtSc</kbd> / <kbd>Shift</kbd>+<kbd>PrtSc</kbd> | Screenshot region → clipboard / file |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>C</kbd> | Capture menu (screenshot/record/OCR/QR/color) |
| <kbd>Super</kbd> + <kbd>F1</kbd> | This key list (opens in a terminal) |
| <kbd>Super</kbd> + Click/Drag | Move/resize window |
| <kbd>Super</kbd> + mouse wheel | Switch workspace |

Full config: `configs/hyprland/` (entry `hyprland.conf` sources `env/appearance/rules/autostart/bindings`)

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

## 🆘 Stuck?

- **Nothing boots / scary vendor error?** Secure Boot is almost certainly still on — see step 3 above.
- **Black screen after login?** Wait 10 seconds (first start is slow), then press <kbd>Super</kbd>+<kbd>Return</kbd>. If a terminal opens, the system is fine — press <kbd>Super</kbd>+<kbd>F1</kbd> for the key list.
- **Installer failed?** Re-run it with `nuit-installer --dry-run` and read the plan; then file an issue with your disk layout (`lsblk`) and where it stopped.
- **Anything else:** [open an issue](https://github.com/SulphShock/NuitOS/issues) — say what you clicked, what you expected, and what happened instead (a phone photo of the screen is perfect).

## 🤝 Contributing

Issues, feature requests, and PRs welcome.

**Keep it coherent.** Gruvbox-dark look, working defaults, no dead code. Big new features go in userland, not the ISO.

**Keep it honest.** If something's broken, say so. If it's a workaround, document why.

---

## 🙏 Honorable mentions

Thanks to the MIT projects this shell learned from. Code names what it does. Full sources in `configs/quickshell/NOTICE.md`.

- BibekBhusal0/omarchy-better-menu - launcher fuzzy ideas
- itsdotdev/omarchy-youtube-music - music backend ideas
- 3EYE3Y3/omarchy-capture-board - capture converter ideas
- brvier/PlanovaQuickShell + Planova - day file format

## 📜 License

MIT. See `LICENSE`.

---

## 📚 References

- [Arch Linux](https://archlinux.org)
- [Hyprland Docs](https://hyprland.org)
- [QuickShell](https://github.com/outfoxxed/quickshell)
- [slick-greeter](https://github.com/linuxmint/slick-greeter) (LightDM greeter, gruvbox config)

---

<p align="center">
  <strong>Nuit OS</strong> — Hyprland + Arch. Gruvbox-dark. Built to work. <br>
  <a href="https://github.com/SulphShock/NuitOS">View on GitHub</a>
</p>
