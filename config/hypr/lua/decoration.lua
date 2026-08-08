-- Decoration settings (migrated from hyprland/decoration.conf)
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
--
-- NOTE: the gsettings `exec` lines from decoration.conf were moved to the
-- startup handler in hyprland.lua. The QT_QPA_PLATFORMTHEME env was moved to
-- lua/env.lua.

hl.config({
    decoration = {
        rounding = 8,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },
})
