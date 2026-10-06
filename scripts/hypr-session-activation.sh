#!/usr/bin/env bash
#
# Restore Hyprland's output configuration after this logind session regains its
# VT. This is useful when two persistent Hyprland sessions share one GPU: the
# active compositor needs to modeset the external outputs again after the DRM
# master handoff.

set -u -o pipefail

LOGIND="${LOGINCTL_BIN:-loginctl}"
HYPRCTL="${HYPRCTL_BIN:-hyprctl}"
POLL_INTERVAL="${HYPR_SESSION_POLL_INTERVAL:-0.5}"
ACTIVATION_DELAY="${HYPR_SESSION_ACTIVATION_DELAY:-1}"
WAYBAR_LAUNCHER="${HYPR_SESSION_WAYBAR_LAUNCHER:-$HOME/.config/waybar/launch.sh}"
LOG_FILE="${HYPR_SESSION_ACTIVATION_LOG:-${XDG_STATE_HOME:-$HOME/.local/state}/hypr/session-activation.log}"

SESSION_ID="${XDG_SESSION_ID:-}"
if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID="$($LOGIND show-user "$(id -un)" --property=Display --value 2>/dev/null || true)"
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "hypr-session-activation: unable to determine the logind session" >&2
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >> "$LOG_FILE"
}

session_active() {
    "$LOGIND" show-session "$SESSION_ID" --property=Active --value 2>/dev/null || true
}

recover_outputs() {
    log "session ${SESSION_ID} activated; reloading Hyprland outputs"

    if ! "$HYPRCTL" reload >> "$LOG_FILE" 2>&1; then
        log "Hyprland reload failed; keeping existing Waybar instance"
        return
    fi

    if [[ -x "$WAYBAR_LAUNCHER" ]]; then
        log "restarting Waybar after output recovery"
        "$WAYBAR_LAUNCHER" >> "$LOG_FILE" 2>&1
    else
        log "Waybar launcher is unavailable: ${WAYBAR_LAUNCHER}"
    fi
}

previous_state="$(session_active)"
log "watching session ${SESSION_ID}; initial state: ${previous_state:-unknown}"

while true; do
    current_state="$(session_active)"

    if [[ "$previous_state" != "yes" && "$current_state" == "yes" ]]; then
        # Let logind hand DRM master back to Hyprland before recreating outputs.
        sleep "$ACTIVATION_DELAY"

        if [[ "$(session_active)" == "yes" ]]; then
            recover_outputs
        fi
    fi

    previous_state="$current_state"
    sleep "$POLL_INTERVAL"
done
