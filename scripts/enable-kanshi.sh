#!/usr/bin/env bash
#
# enable-kanshi.sh
# Capture the current live monitor layout, save it as a named kanshi profile,
# switch hyprland.conf to kanshi mode, and start kanshi.
#
# Workflow:
#   1. Arrange monitors with nwg-displays (monitors.conf is live via hyprland.conf).
#   2. Run this script; it will prompt for a profile name.
#   3. Kanshi takes over from that point — nwg-displays changes will have no effect
#      until you run disable-kanshi.
#
# To revert to nwg-displays mode: run disable-kanshi.sh

set -euo pipefail

KANSHI_CONFIG="${KANSHI_CONFIG:-$HOME/.config/kanshi/config}"
KANSHI_MODE_CONF="${KANSHI_MODE_CONF:-$HOME/.config/hypr/kanshi-mode.lua}"

# ── Sanity checks ────────────────────────────────────────────────────────────
command -v hyprctl >/dev/null || { echo "error: hyprctl not found (is Hyprland running?)" >&2; exit 1; }
command -v jq      >/dev/null || { echo "error: jq not found" >&2; exit 1; }

# ── Prompt for profile name ──────────────────────────────────────────────────
echo "Connected monitors:"
hyprctl monitors -j | jq -r '.[] | "  \(.name)  \(.width)x\(.height)@\(.refreshRate|round)Hz  \(.make) \(.model)"'
echo ""

read -rp "Profile name (e.g. docked_full, laptop): " PROFILE_NAME
PROFILE_NAME="${PROFILE_NAME// /_}"   # replace spaces with underscores

if [[ -z "$PROFILE_NAME" || "$PROFILE_NAME" == -* ]]; then
  echo "error: invalid profile name '${PROFILE_NAME}'" >&2
  exit 1
fi

# ── Generate the profile block from live hyprctl state ───────────────────────
generate_profile() {
  echo "profile ${PROFILE_NAME} {"
  hyprctl monitors -j | jq -r '
    .[] | [.name, .width, .height, ((.refreshRate * 1000 | round) / 1000), .x, .y, .scale] | @tsv
  ' | while IFS=$'\t' read -r name w h rate x y scale; do
      printf '    output %s mode %sx%s@%sHz position %s,%s scale %s\n' \
        "$name" "$w" "$h" "$rate" "$x" "$y" "$scale"
    done
  echo "}"
}

PROFILE_BLOCK="$(generate_profile)"

# ── Insert or replace profile in kanshi config ───────────────────────────────
mkdir -p "$(dirname "$KANSHI_CONFIG")"

if [[ ! -f "$KANSHI_CONFIG" ]]; then
  printf '%s\n' "$PROFILE_BLOCK" > "$KANSHI_CONFIG"
  echo "Created ${KANSHI_CONFIG} with profile '${PROFILE_NAME}'."
elif grep -qE "^[[:space:]]*profile[[:space:]]+${PROFILE_NAME}[[:space:]]*\{" "$KANSHI_CONFIG"; then
  # Replace existing profile (everything between 'profile NAME {' and its closing '}')
  # Use awk: print lines outside the matched profile block, then append new block.
  TMP="$(mktemp)"
  awk -v name="$PROFILE_NAME" '
    /^[[:space:]]*profile[[:space:]]+/ && $0 ~ ("profile[[:space:]]+"name"[[:space:]]*\\{") {
      skip=1; depth=0
    }
    skip {
      for (i=1;i<=length($0);i++) {
        c=substr($0,i,1)
        if (c=="{") depth++
        if (c=="}") { depth--; if (depth<=0) { skip=0; next } }
      }
      next
    }
    { print }
  ' "$KANSHI_CONFIG" > "$TMP"
  printf '\n%s\n' "$PROFILE_BLOCK" >> "$TMP"
  mv "$TMP" "$KANSHI_CONFIG"
  echo "Replaced existing profile '${PROFILE_NAME}' in ${KANSHI_CONFIG}."
else
  printf '\n%s\n' "$PROFILE_BLOCK" >> "$KANSHI_CONFIG"
  echo "Appended profile '${PROFILE_NAME}' to ${KANSHI_CONFIG}."
fi

# ── Switch kanshi-mode.lua to kanshi mode ────────────────────────────────────
cat > "$KANSHI_MODE_CONF" << 'EOF'
-- kanshi-mode.lua — KANSHI MODE
-- Managed by enable-kanshi / disable-kanshi — do not edit manually.
hl.on("hyprland.start", function() hl.exec_cmd("kanshi") end)
-- require("monitors")  -- disabled in kanshi mode
EOF
echo "kanshi-mode.lua set to kanshi mode."

# ── Start / reload kanshi ─────────────────────────────────────────────────────
echo ""
echo "Starting kanshi..."
killall kanshi 2>/dev/null || true
sleep 0.3
kanshi &
echo "Kanshi started (pid $!)."
echo ""
echo "Done. Kanshi is now managing your monitor layout."
echo "To revert to nwg-displays mode: disable-kanshi"
