-- Layer rules (migrated from the layerrule {} blocks in hyprland.conf)
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ (layer rules)

hl.layer_rule({
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0.01,
})

hl.layer_rule({
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0.01,
})
