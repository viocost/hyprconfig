#!/usr/bin/env bash
#
# generate-kanshi-profile.sh
# Generate a kanshi profile from the CURRENT live monitor layout (via hyprctl).
#
# Typical workflow:
#   1. Arrange your monitors however you like (nwg-displays, or hyprctl).
#   2. Capture that layout as a named kanshi profile:
#        generate-kanshi-profile.sh <profile-name>            # print to stdout
#        generate-kanshi-profile.sh <profile-name> --append   # append to config
#   3. Reload kanshi:  killall kanshi 2>/dev/null; kanshi &   (or just relog)
#
# The profile is emitted using CONNECTOR NAMES (DP-1, DP-4, eDP-1) so it stays
# consistent with ~/.config/hypr/hyprland/monitor-vars.conf ($monitor1/2/3) and
# your workspace<->monitor bindings in workspaces.conf.

set -euo pipefail

KANSHI_CONFIG="${KANSHI_CONFIG:-$HOME/.config/kanshi/config}"
VARS_CONF="${MONITOR_VARS_CONF:-$HOME/.config/hypr/hyprland/monitor-vars.conf}"

usage() {
  echo "Usage: $(basename "$0") <profile-name> [--append]" >&2
  echo "  --append   append the profile to ${KANSHI_CONFIG} (default: print to stdout)" >&2
  exit 1
}

PROFILE_NAME="${1:-}"
APPEND=0
[[ "${2:-}" == "--append" ]] && APPEND=1

[[ -z "$PROFILE_NAME" || "$PROFILE_NAME" == -* ]] && usage
command -v hyprctl >/dev/null || { echo "error: hyprctl not found (is Hyprland running?)" >&2; exit 1; }
command -v jq >/dev/null      || { echo "error: jq not found" >&2; exit 1; }

# Map connector-name -> $monitorN label from monitor-vars.conf (used for comments only).
declare -A VARLABEL
if [[ -f "$VARS_CONF" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^\$([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*([^[:space:]#]+) ]]; then
      VARLABEL["${BASH_REMATCH[2]}"]="\$${BASH_REMATCH[1]}"
    fi
  done < "$VARS_CONF"
fi

generate() {
  echo "profile ${PROFILE_NAME} {"
  # jq rounds the refresh rate to whole mHz (e.g. 60.00100 -> 60.001); kanshi
  # then picks the closest available mode, so exact rates are not required.
  hyprctl monitors -j | jq -r '
    .[] | [
      .name, .width, .height,
      ((.refreshRate * 1000 | round) / 1000),
      .x, .y, .scale,
      (.make // ""), (.model // ""), (.serial // "")
    ] | @tsv
  ' | while IFS=$'\t' read -r name w h rate x y scale make model serial; do
      label="${VARLABEL[$name]:-}"
      desc="$(echo "${make} ${model}" | sed 's/^ *//; s/ *$//')"
      comment=""
      [[ -n "$desc" ]]   && comment=" # ${desc}"
      [[ -n "$serial" ]] && comment+=" (${serial})"
      [[ -n "$label" ]]  && comment+=" -> ${label}"
      printf '    output %s mode %sx%s@%sHz position %s,%s scale %s%s\n' \
        "$name" "$w" "$h" "$rate" "$x" "$y" "$scale" "$comment"
    done
  echo "}"
}

profile_output="$(generate)"

if [[ "$APPEND" -eq 1 ]]; then
  mkdir -p "$(dirname "$KANSHI_CONFIG")"
  if [[ -f "$KANSHI_CONFIG" ]] && grep -qE "^[[:space:]]*profile[[:space:]]+${PROFILE_NAME}[[:space:]]*\{" "$KANSHI_CONFIG"; then
    echo "error: profile '${PROFILE_NAME}' already exists in ${KANSHI_CONFIG}" >&2
    echo "       edit/remove it first, or choose another name." >&2
    exit 1
  fi
  { printf '\n%s\n' "$profile_output"; } >> "$KANSHI_CONFIG"
  echo "Appended profile '${PROFILE_NAME}' to ${KANSHI_CONFIG}" >&2
  echo "Reload with: killall kanshi 2>/dev/null; kanshi &" >&2
else
  printf '%s\n' "$profile_output"
fi
