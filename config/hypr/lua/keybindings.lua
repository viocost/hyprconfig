-- Keybindings (migrated from hyprland/keybindings.conf)
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mod = "SUPER"

-- vim-style movement keys
local L, D, U, R = "h", "j", "k", "l"

-- Workspace switch mapping: key -> workspace id
local ws_main  = { { "1", 1 }, { "2", 2 }, { "3", 3 }, { "4", 4 }, { "5", 5 },
                   { "6", 6 }, { "7", 7 }, { "8", 8 }, { "9", 9 }, { "0", 10 } }
local ws_shift = { { "1", 11 }, { "2", 12 }, { "3", 13 }, { "4", 14 }, { "5", 15 },
                   { "6", 16 }, { "7", 17 }, { "8", 18 }, { "9", 19 }, { "0", 20 } }

-- ============================================================================
-- Applications
-- ============================================================================
hl.bind(mod .. " + Return",        hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + C",             hl.dsp.exec_cmd("/usr/bin/chromium"))
hl.bind(mod .. " + D",             hl.dsp.exec_cmd("rofi -modi drun -show drun -config ~/.config/rofi/rofidmenu.rasi"))
hl.bind("F9",                      hl.dsp.exec_cmd("rofi -modi drun -show drun -config ~/.config/rofi/rofidmenu.rasi"))
hl.bind(mod .. " + T",             hl.dsp.exec_cmd("rofi -show window -config ~/.config/rofi/rofidmenu.rasi"))
hl.bind(mod .. " + F8",            hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("thunar"))
hl.bind("CTRL + SHIFT + E",        hl.dsp.exec_cmd("emacs"))
hl.bind("CTRL + SHIFT + N",        hl.dsp.exec_cmd("neovide --neovim-bin /home/kostia/.local/bin/lvim"))
hl.bind(mod .. " + N",             hl.dsp.exec_cmd("~/.local/bin/scripts/cli/rofi-neovide.sh"))
hl.bind("CTRL + SHIFT + Escape",   hl.dsp.exec_cmd("kitty -e bpytop"))
hl.bind("CTRL + Print",            hl.dsp.exec_cmd("~/.local/bin/scripts/screenshot.sh"))

-- ============================================================================
-- Window management
-- ============================================================================
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprctl activewindow -j | jq -r '.pid' | xargs kill -9"))
hl.bind(mod .. " + Space",     hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))

-- Focus movement (vim keys; h/l use custom cross-monitor scripts)
hl.bind(mod .. " + " .. L, hl.dsp.exec_cmd("~/.local/bin/scripts/focus-left.sh"))
hl.bind(mod .. " + " .. D, hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + " .. U, hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + " .. R, hl.dsp.exec_cmd("~/.local/bin/scripts/focus-right.sh"))

-- Focus movement (arrow keys)
hl.bind(mod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))

-- Move windows (vim keys)
hl.bind(mod .. " + SHIFT + " .. L, hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + " .. D, hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + " .. U, hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + " .. R, hl.dsp.window.move({ direction = "right" }))

-- Move windows (arrow keys)
hl.bind(mod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "right" }))

-- ============================================================================
-- Workspaces
-- ============================================================================
for _, b in ipairs(ws_main) do
    hl.bind(mod .. " + " .. b[1], hl.dsp.focus({ workspace = b[2] }))
end
for _, b in ipairs(ws_shift) do
    hl.bind(mod .. " + SHIFT + " .. b[1], hl.dsp.focus({ workspace = b[2] }))
end

-- Workspace navigation
hl.bind("ALT + Tab",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + Tab",     hl.dsp.focus({ workspace = "previous" }))

-- ============================================================================
-- Move mode (submap, like i3's move mode) — SUPER + M
-- ============================================================================
hl.bind(mod .. " + M", hl.dsp.submap("move"))
hl.define_submap("move", function()
    local function move_and_reset(n)
        return function()
            hl.dispatch(hl.dsp.window.move({ workspace = n, follow = true }))
            hl.dispatch(hl.dsp.submap("reset"))
        end
    end
    for _, b in ipairs(ws_main) do
        hl.bind(mod .. " + " .. b[1], move_and_reset(b[2]))
    end
    for _, b in ipairs(ws_shift) do
        hl.bind(mod .. " + SHIFT + " .. b[1], move_and_reset(b[2]))
    end
    hl.bind(mod .. " + M", hl.dsp.submap("reset"))
    hl.bind("Escape",      hl.dsp.submap("reset"))
end)

-- ============================================================================
-- Layouts
-- ============================================================================
hl.bind(mod .. " + V",         hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + S",         function() hl.config({ general = { layout = "master" } }) end)
hl.bind(mod .. " + E",         function() hl.config({ general = { layout = "dwindle" } }) end)

-- ============================================================================
-- Resize mode (submap, like i3) — SUPER + R
-- ============================================================================
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local step = 20
    -- vim keys
    hl.bind(L, hl.dsp.window.resize({ x = -step, y = 0,     relative = true }), { repeating = true })
    hl.bind(D, hl.dsp.window.resize({ x = 0,     y = step,  relative = true }), { repeating = true })
    hl.bind(U, hl.dsp.window.resize({ x = 0,     y = -step, relative = true }), { repeating = true })
    hl.bind(R, hl.dsp.window.resize({ x = step,  y = 0,     relative = true }), { repeating = true })
    -- arrow keys
    hl.bind("Left",  hl.dsp.window.resize({ x = -step, y = 0,     relative = true }), { repeating = true })
    hl.bind("Down",  hl.dsp.window.resize({ x = 0,     y = step,  relative = true }), { repeating = true })
    hl.bind("Up",    hl.dsp.window.resize({ x = 0,     y = -step, relative = true }), { repeating = true })
    hl.bind("Right", hl.dsp.window.resize({ x = step,  y = 0,     relative = true }), { repeating = true })
    -- exit
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- ============================================================================
-- System control
-- ============================================================================
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + Escape",    hl.dsp.exec_cmd("wlogout"))
hl.bind("CTRL + ALT + X",      hl.dsp.exec_cmd("wlogout"))

-- ============================================================================
-- Media keys (locked = work while lockscreen active)
-- ============================================================================
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -t 1000 "Volume Up"]]),          { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -t 1000 "Volume Down"]]),        { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -t 1000 "Volume Mute Toggle"]]), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"),       { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true })

-- ============================================================================
-- Mouse bindings
-- ============================================================================
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
