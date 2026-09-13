-- Hyprland Keybindings
-- Reference mirror of bindings.conf (the LIVE set, sourced by hyprland.conf).
-- Kept in sync line-for-line in meaning; drift guard enforces it.

local mainMod = "SUPER"
local nuitBin = "$HOME/.local/bin/"

-- ── Applications ──────────────────────────────────────────
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open https://"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("nuit-browser-private"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("xdg-open $HOME"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call gsb toggleActivities"))

-- ── Window Management (togglesplit on G: J is Vim focus-down) ──
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + G", hl.dsp.layout("togglesplit"))

-- ── QuickShell panels ─────────────────────────────────────
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("qs ipc call gsb toggleQuickSettings"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs ipc call gsb toggleCalendar"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("qs ipc call gsb toggleSettings"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call gsb toggleNotifs"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs ipc call gsb toggleReminders"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call gsb toggleWifi"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("qs ipc call gsb toggleBluetooth"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call gsb toggleCaptureBoard"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call gsb toggleYouTubeMusic"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call gsb toggleNightLight"))

-- ── Focus (arrows, ALT+arrows, SUPER+HJK; SUPER+L stays lock) ──
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + LEFT", hl.dsp.focus({ direction = "l" }))
hl.bind("ALT + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind("ALT + UP", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + DOWN", hl.dsp.focus({ direction = "d" }))

-- ── Workspaces (SHIFT = move + follow, CTRL = send, stay put) ──
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.window.move({ workspace = 10, follow = false }))

-- ── Scroll Workspaces ─────────────────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("mouse:275", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("mouse:276", hl.dsp.focus({ workspace = "e+1" }))

-- ── Mouse Bindings ────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Swap Windows (arrows + HJKL) ──────────────────────────
hl.bind(mainMod .. " + SHIFT + LEFT", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + UP", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + DOWN", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }))

-- ── Resize With Keys (arrows + HJKL) ──────────────────────
hl.bind(mainMod .. " + CTRL + LEFT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -20 0"))
hl.bind(mainMod .. " + CTRL + RIGHT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 20 0"))
hl.bind(mainMod .. " + CTRL + UP", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -20"))
hl.bind(mainMod .. " + CTRL + DOWN", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 20"))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -20 0"))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 20"))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -20"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 20 0"))

-- ── Cycle windows (most-recent-first) ─────────────────────
hl.bind("ALT + TAB", hl.dsp.exec_cmd("hyprctl dispatch cyclenext"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("hyprctl dispatch cyclenext prev"))

-- ── Wallpaper (SHIFT+SPACE next, CTRL+SPACE pick) ───────
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("nuit-theme-bg-next"))
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("nuit-theme-bg-pick"))

-- ── Screenshots ───────────────────────────────────────────
hl.bind("PRINT", hl.dsp.exec_cmd("sh -c 'g=$(slurp) || exit 0; grim -g \"$g\" - | wl-copy --type image/png'"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("sh -c 'g=$(slurp) || exit 0; mkdir -p \"$HOME/Pictures\" && grim -g \"$g\" \"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'\""))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind("ALT + PRINT", hl.dsp.exec_cmd(nuitBin .. "nuit-screenrecord region"))
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd("nuit-capture-menu"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("qs ipc call gsb toggleKeybinds"))

-- ── Session (power dialog lives inside QuickSettings) ─────
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("qs ipc call gsb toggleQuickSettings"))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd("hyprlock"))

-- ── Fn keys: volume / mic / media ─────────────────────────
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- ── Fn+F5 refresh → reload Hyprland ───────────────────────
hl.bind("XF86Reload", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("XF86Refresh", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + F5", hl.dsp.exec_cmd("hyprctl reload"))

-- ── Fn+F7 idle → toggle auto dim/lock/suspend ─────────────
hl.bind("XF86Tools", hl.dsp.exec_cmd("nuit-idle-toggle"))
hl.bind(mainMod .. " + F7", hl.dsp.exec_cmd("nuit-idle-toggle"))

-- ── Fn+F8 lock (XF86ScreenSaver is what laptops send) ─────
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("hyprlock"))

-- ── Brightness keys (Fn+F11/F12 on most laptops) ──────────
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
