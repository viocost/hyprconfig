-- Environment variables (migrated from hyprland/env.conf)
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

local home = os.getenv("HOME") or ""

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- This machine's connected outputs use the Intel i915 KMS device. Hyprland's
-- Aquamarine backend uses AQ_DRM_DEVICES (not wlroots' WLR_DRM_DEVICES).
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")

-- Wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Electron
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GTK
hl.env("GTK_THEME", "Arc:dark")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- NOTE: was qt5ct in env.conf but decoration.conf overrode it to qt6ct (load
-- order), so qt6ct is the effective value; preserved here.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Scripts path
hl.env("SCRIPTS", home .. "/.local/bin/scripts")
