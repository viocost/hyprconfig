#!/usr/bin/env bash
#
# shim-up.sh <slug>
#
# Ensures a Hyprland command-socket translation proxy (proxy.py) is running for
# the given <slug>, so legacy tools can be launched with
#     HYPRLAND_INSTANCE_SIGNATURE=<slug>
# and have their command traffic translated to the Lua form Hyprland 0.56+
# requires. See README.md.
#
# It creates $XDG_RUNTIME_DIR/hypr/<slug>/ containing:
#   .socket2.sock -> symlink to the REAL event socket (events pass through)
#   .socket.sock  -> the proxy's own listening socket (commands translated)
#
# Keep <slug> short: AF_UNIX paths are limited to ~108 chars.

set -euo pipefail

SLUG="${1:?usage: shim-up.sh <slug>}"

HIS="${HYPRLAND_INSTANCE_SIGNATURE:?HYPRLAND_INSTANCE_SIGNATURE not set}"
REAL_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
REAL_DIR="$REAL_RUNTIME/hypr/$HIS"
REAL_CMD_SOCK="$REAL_DIR/.socket.sock"
REAL_EVT_SOCK="$REAL_DIR/.socket2.sock"

PROXY_DIR="$REAL_RUNTIME/hypr/$SLUG"
PROXY_CMD_SOCK="$PROXY_DIR/.socket.sock"
PIDFILE="$PROXY_DIR/proxy.pid"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_PY="$SCRIPT_DIR/proxy.py"

mkdir -p "$PROXY_DIR"
ln -sf "$REAL_EVT_SOCK" "$PROXY_DIR/.socket2.sock"

# Stop any previous proxy for this slug (tracked via pidfile to avoid pkill
# matching ourselves). The real signature changes each login, so always rebind.
if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
fi
rm -f "$PROXY_CMD_SOCK"

python3 "$PROXY_PY" "$PROXY_CMD_SOCK" "$REAL_CMD_SOCK" </dev/null >>"${HYPR_LUA_SHIM_LOG:-/dev/null}" 2>&1 &
PROXY_PID=$!
echo "$PROXY_PID" > "$PIDFILE"
disown 2>/dev/null || true

# Wait until the proxy actually accepts connections (clients may panic on a
# connection-refused if they start too early).
for _ in $(seq 1 100); do
    if python3 - "$PROXY_CMD_SOCK" <<'PY' 2>/dev/null
import socket, sys
s = socket.socket(socket.AF_UNIX); s.settimeout(0.2); s.connect(sys.argv[1]); s.close()
PY
    then
        exit 0
    fi
    sleep 0.1
done

echo "hypr-lua-shim: proxy for '$SLUG' failed to become ready" >&2
exit 1
