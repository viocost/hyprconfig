#!/usr/bin/env bash
#
# hypr-autoname-shim launcher.
#
# Runs hyprland-autoname-workspaces behind proxy.py so its legacy
# "renameworkspace" dispatches are translated to the Lua form that
# Hyprland 0.56+ (Lua config) requires. See README.md in this directory.
#
# Started from hyprland.lua as an exec-once at login:
#     hl.exec_cmd("~/hyprconfig/hypr-autoname-shim/launch.sh")
#
# Environment / arguments:
#   $1 or AUTONAME_CONFIG   path to the tool's TOML config
#                           (default: ~/.config/hypr/hyprland-autoname-workspaces.toml)
#   HYPR_AUTONAME_PROXY_LOG  if set, proxy.py logs translated commands there
#   AUTONAME_FAKE_HIS        short fake instance name for the proxy dir
#                            (default: "autoname"; keep it short — AF_UNIX paths
#                            are limited to ~108 chars and the real signature is
#                            already ~60)

set -euo pipefail

CONFIG="${1:-${AUTONAME_CONFIG:-$HOME/.config/hypr/hyprland-autoname-workspaces.toml}}"
FAKE_HIS="${AUTONAME_FAKE_HIS:-autoname}"

HIS="${HYPRLAND_INSTANCE_SIGNATURE:?HYPRLAND_INSTANCE_SIGNATURE not set}"
REAL_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
REAL_DIR="$REAL_RUNTIME/hypr/$HIS"
REAL_CMD_SOCK="$REAL_DIR/.socket.sock"
REAL_EVT_SOCK="$REAL_DIR/.socket2.sock"

PROXY_DIR="$REAL_RUNTIME/hypr/$FAKE_HIS"
PROXY_CMD_SOCK="$PROXY_DIR/.socket.sock"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_PY="$SCRIPT_DIR/proxy.py"

mkdir -p "$PROXY_DIR"

# The event socket is not translated — pass it straight through so the tool
# receives genuine Hyprland events.
ln -sf "$REAL_EVT_SOCK" "$PROXY_DIR/.socket2.sock"

# (Re)start the proxy. Remove any stale socket first so the readiness probe
# below only succeeds once THIS proxy instance is actually accepting
# connections — the tool panics on a connection-refused.
pkill -f "proxy.py $PROXY_CMD_SOCK" 2>/dev/null || true
rm -f "$PROXY_CMD_SOCK"
python3 "$PROXY_PY" "$PROXY_CMD_SOCK" "$REAL_CMD_SOCK" &
PROXY_PID=$!

ready=0
for _ in $(seq 1 100); do
    if python3 - "$PROXY_CMD_SOCK" <<'PY' 2>/dev/null
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.settimeout(0.2)
s.connect(sys.argv[1])
s.close()
PY
    then
        ready=1
        break
    fi
    sleep 0.1
done
[ "$ready" = 1 ] || { echo "hypr-autoname-shim: proxy failed to become ready" >&2; kill "$PROXY_PID" 2>/dev/null || true; exit 1; }

cleanup() { kill "$PROXY_PID" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

# Point the tool at the proxy instance via a short fake signature; the real
# XDG_RUNTIME_DIR is kept so all other paths resolve normally.
export HYPRLAND_INSTANCE_SIGNATURE="$FAKE_HIS"
exec hyprland-autoname-workspaces --config "$CONFIG"
