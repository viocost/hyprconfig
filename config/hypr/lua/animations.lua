-- Animations (migrated from hyprland/animations.conf)
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    animations = {
        enabled = true,
    },
})

-- bezier = myBezier, 0.05, 0.9, 0.1, 1.05
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

-- animation = <leaf>, <enabled>, <speed>, <curve>[, <style>]
hl.animation({ leaf = "windows",     enabled = true,  speed = 3, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 3, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true,  speed = 5, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true,  speed = 4, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true,  speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = false, speed = 3, bezier = "default" })
