-- Hyprland configuration (Lua format)
-- Migrated from the legacy .conf format (removed in Hyprland 0.57).
-- Based on i3wm config from arconfig.
--
-- Config is split into modules under ~/.config/hypr/lua/ and required below.
-- Each require() is an isolated error scope, so a mistake in one module will
-- not stop the others from loading.

------------------------------------------------------------------------------
-- Monitor connector names — single source of truth
-- Parse hyprland/monitor-vars.conf ($monitorN = NAME) into _G.MONITORS so both
-- Hyprland (lua/workspaces.lua) and the external scripts stay in sync.
------------------------------------------------------------------------------
_G.MONITORS = {}
do
    local path = (os.getenv("HOME") or "") .. "/.config/hypr/hyprland/monitor-vars.conf"
    local f = io.open(path, "r")
    if f then
        for line in f:lines() do
            local n, name = line:match("^%s*%$monitor(%d+)%s*=%s*([^%s#]+)")
            if n and name then
                _G.MONITORS[tonumber(n)] = name
            end
        end
        f:close()
    end
end

------------------------------------------------------------------------------
-- Monitors
-- Fallback catch-all; specific monitors come from monitors.lua (required via
-- kanshi-mode.lua in nwg-displays mode).
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
------------------------------------------------------------------------------
hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 })

-- Monitor layout — managed by enable-kanshi / disable-kanshi via kanshi-mode.lua
require("kanshi-mode")

------------------------------------------------------------------------------
-- Configuration modules
------------------------------------------------------------------------------
require("lua/env")
require("lua/general")
require("lua/decoration")
require("lua/animations")
require("lua/input")
require("lua/workspaces")
require("lua/windowrules")
require("lua/layerrules")
require("lua/keybindings")
-- Required last so its binds take priority over any same-key binds above.
require("lua/hyprcaffeine")

------------------------------------------------------------------------------
-- Autostart (exec-once)
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
------------------------------------------------------------------------------
hl.on("hyprland.start", function()
    -- Generate hyprpaper.conf + monitor-env.sh from monitor-vars.conf
    hl.exec_cmd("apply-monitor-vars")

    hl.exec_cmd("~/.config/waybar/launch.sh")
    hl.exec_cmd("~/hyprconfig/hypr-autoname-shim/launch.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("blueman-tray")
    hl.exec_cmd("hyprpolkitagent")

    -- GTK theme (was `exec` in decoration.conf)
    hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])
    hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"]])
end)
