-- Input configuration (migrated from hyprland/input.conf)
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us,ru,il",
        kb_options = "caps:escape,grp:alt_shift_toggle",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Per-device configuration
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name   = "acd02",
    output = "DP-1",
})
