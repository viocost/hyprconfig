-- General settings (migrated from hyprland/general.conf)
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#general

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = 2,

        -- ArcoLinux default theme colors
        col = {
            active_border   = "rgba(6790EBee)",
            inactive_border = "rgba(222222aa)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    -- Renderer settings for NVIDIA
    render = {
        direct_scanout = true,
    },

    -- Cursor settings for NVIDIA
    cursor = {
        no_hardware_cursors = true,
        enable_hyprcursor   = true,
    },
})
