-- Hyprland Keybindings

local mainMod = "SUPER"
local nuitBin = "$HOME/.local/bin/"

-- ── Applications ──────────────────────────────────────────
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))

-- ── Window Management ─────────────────────────────────────
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- ── Focus ─────────────────────────────────────────────────
-- SUPER+Left/Right = prev/next workspace (click workspaces in TopBar works too).
-- Focus left/right moved to ALT+arrows so both stay available.
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + LEFT", hl.dsp.focus({ direction = "l" }))
hl.bind("ALT + RIGHT", hl.dsp.focus({ direction = "r" }))
hl.bind("ALT + UP", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + DOWN", hl.dsp.focus({ direction = "d" }))

-- ── Move Windows ──────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + LEFT", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + UP", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + DOWN", hl.dsp.window.swap({ direction = "d" }))

-- ── Resize ────────────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + LEFT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -20 0"))
hl.bind(mainMod .. " + CTRL + RIGHT", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 20 0"))
hl.bind(mainMod .. " + CTRL + UP", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -20"))
hl.bind(mainMod .. " + CTRL + DOWN", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 20"))

-- ── Workspaces ────────────────────────────────────────────
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- ── Scroll Workspaces ─────────────────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("mouse:275", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("mouse:276", hl.dsp.focus({ workspace = "e+1" }))

-- ── Mouse Bindings ────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Scratchpad ────────────────────────────────────────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- ── Screenshots ───────────────────────────────────────────
hl.bind("PRINT", hl.dsp.exec_cmd("sh -c 'g=$(slurp) || exit 0; grim -g \"$g\" - | wl-copy --type image/png'"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("sh -c 'g=$(slurp) || exit 0; mkdir -p \"$HOME/Pictures\" && grim -g \"$g\" \"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'\""))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind("ALT + PRINT", hl.dsp.exec_cmd(nuitBin .. "nuit-screenrecord region"))
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd("sh -c 'g=$(slurp) || exit 0; grim -g \"$g\" - | wl-copy --type image/png'"))

-- ── Brightness keys (laptop panel) ──────────────────────────
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))

-- ── Launcher ──────────────────────────────────────────────
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call gsb toggleActivities"))

-- ── Wallpaper ─────────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("nuit-theme-bg-next"))

-- ── Session ───────────────────────────────────────────────
-- (wlogout not installed → Super+Escape opens Quick Settings power menu)
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("qs ipc call gsb toggleQuickSettings"))
hl.bind(mainMod .. " + SHIFT + ESCAPE", hl.dsp.exec_cmd("systemctl reboot"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
