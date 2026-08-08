-- Workspace configuration (migrated from hyprland/workspaces.conf)
-- Monitor connector names come from _G.MONITORS, parsed from
-- hyprland/monitor-vars.conf by hyprland.lua (single source of truth shared
-- with the external scripts).

local mon = _G.MONITORS or {}
local m1 = mon[1] or "DP-1"   -- Left monitor
local m2 = mon[2] or "DP-6"   -- Middle monitor
local m3 = mon[3] or "eDP-1"  -- Internal laptop monitor

-- Workspace -> monitor assignments (1-8 left, 9-16 middle, 17-20 internal)
for ws = 1, 8 do
    hl.workspace_rule({ workspace = tostring(ws), monitor = m1, default = (ws == 1) or nil })
end
for ws = 9, 16 do
    hl.workspace_rule({ workspace = tostring(ws), monitor = m2, default = (ws == 9) or nil })
end
for ws = 17, 20 do
    hl.workspace_rule({ workspace = tostring(ws), monitor = m3, default = (ws == 17) or nil })
end

-- Layout / misc settings
hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        swallow_regex            = "^(kitty)$",
    },
    debug = {
        vfr = true,
    },
})
