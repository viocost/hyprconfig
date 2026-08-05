#!/usr/bin/env bash
#
# disable-kanshi.sh
# Stop kanshi and hand monitor management back to nwg-displays / monitors.conf.
#
# Rewrites kanshi-mode.conf to nwg-displays mode, reloads Hyprland so the last
# nwg-displays layout (monitors.conf) takes effect immediately.
#
# To switch back to kanshi mode: enable-kanshi

set -euo pipefail

KANSHI_MODE_CONF="${KANSHI_MODE_CONF:-$HOME/.config/hypr/kanshi-mode.conf}"

# ── Stop kanshi ───────────────────────────────────────────────────────────────
if killall kanshi 2>/dev/null; then
  echo "Kanshi stopped."
else
  echo "Kanshi was not running."
fi

# ── Switch kanshi-mode.conf to nwg-displays mode ─────────────────────────────
cat > "$KANSHI_MODE_CONF" << 'EOF'
# kanshi-mode.conf — NWG-DISPLAYS MODE
# Managed by enable-kanshi / disable-kanshi — do not edit manually.
# exec-once = kanshi
source = ~/.config/hypr/monitors.conf
EOF
echo "kanshi-mode.conf set to nwg-displays mode."

# ── Reload Hyprland ───────────────────────────────────────────────────────────
echo "Reloading Hyprland..."
hyprctl reload
echo ""
echo "Done. nwg-displays / monitors.conf is now managing your monitor layout."
echo "To switch back to kanshi mode: enable-kanshi"
