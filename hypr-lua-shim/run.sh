#!/usr/bin/env bash
#
# run.sh <slug> <command> [args...]
#
# Convenience wrapper: brings up the translation proxy for <slug> (via
# shim-up.sh) and then execs <command> with HYPRLAND_INSTANCE_SIGNATURE=<slug>
# so its command traffic is translated. Suitable for single-process tools, e.g.
#
#   run.sh autoname hyprland-autoname-workspaces --config ~/.config/hypr/....toml
#
# For launchers that start several processes (e.g. multiple waybar bars), call
# shim-up.sh once yourself, then export HYPRLAND_INSTANCE_SIGNATURE=<slug> and
# start them.

set -euo pipefail

SLUG="${1:?usage: run.sh <slug> <command> [args...]}"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/shim-up.sh" "$SLUG"

export HYPRLAND_INSTANCE_SIGNATURE="$SLUG"
exec "$@"
