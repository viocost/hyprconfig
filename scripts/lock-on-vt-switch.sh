#!/bin/bash

# Locks this session immediately when its VT is switched away from,
# instead of waiting for the hypridle idle timeout. Relies on hypridle
# already being configured to lock on logind's Lock signal (see
# config/hypr/hypridle.conf), which `loginctl lock-session` triggers.

SESSION_ID="${XDG_SESSION_ID:-$(loginctl show-user "$(whoami)" -p Display --value)}"

was_active=yes
while true; do
    now_active="$(loginctl show-session "$SESSION_ID" -p Active --value 2>/dev/null)"
    if [[ "$was_active" == "yes" && "$now_active" == "no" ]]; then
        loginctl lock-session "$SESSION_ID"
    fi
    was_active="$now_active"
    sleep 1
done
