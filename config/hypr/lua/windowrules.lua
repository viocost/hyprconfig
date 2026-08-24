-- Window rules (migrated from hyprland/windowrules.conf)
-- windowrulev2 = <rule>, <matchers>  ->  hl.window_rule({ match = {...}, <rule> })
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Floating windows
local float_classes = {
    "^(zoom)$",
    "^(Yad)$",
    "^(Galculator)$",
    "^(blueberry.py)$",
    "^(Xsane)$",
    "^(Pavucontrol)$",
    "^(qt5ct)$",
    "^(Bluetooth-sendto)$",
    "^(Pamac-manager)$",
    "^(Xfce4-appfinder)$",
    "^(Xfce4-taskmanager)$",
}
for _, cls in ipairs(float_classes) do
    hl.window_rule({ match = { class = cls }, float = true })
end

local float_titles = {
    "^(About)$",
    "^(Copying)$",
    "^(Deleting)$",
    "^(Moving)$",
    "^(.*Preferences.*)$",
    "^(File Operation Progress)$",
}
for _, t in ipairs(float_titles) do
    hl.window_rule({ match = { title = t }, float = true })
end

-- Zoom - no focus
hl.window_rule({ match = { class = "^(zoom)$" }, no_focus = true })

-- File chooser dialog: size + center
hl.window_rule({ match = { title = "^(Open File)$" }, size = { 1920, 1080 }, center = true })
hl.window_rule({ match = { title = "^(Save File)$" }, size = { 1920, 1080 }, center = true })

-- Focus on specific apps when they request activation
hl.window_rule({ match = { class = "^(kitty)$" },    focus_on_activate = true })
hl.window_rule({ match = { class = "^(thunar)$" },   focus_on_activate = true })
hl.window_rule({ match = { class = "^(Chromium)$" }, focus_on_activate = true })

-- Obsidian desktop app - Settings windows
hl.window_rule({ match = { class = "^md.obsidian.Obsidian$", title = "^Settings.*" }, float = true })

-- Bitwarden in Chrome - Settings windows
hl.window_rule({ match = { class = "^chrome-.*" }, float = true })
hl.window_rule({ match = { title = "^Bitwarden$" }, float = true })
