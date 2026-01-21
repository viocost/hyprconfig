#!/bin/bash

if pgrep -x openvpn >/dev/null 2>/dev/null; then
    # VPN is connected
    cat <<EOF
{"text": "<span foreground=\"#d14d02\">  VPN</span>", "tooltip": "VPN Connected", "class": "vpn-connected"}
EOF
else
    # VPN is disconnected
    cat <<EOF
{"text": "<span foreground=\"#555\"><s>VPN</s></span>", "tooltip": "VPN Disconnected", "class": "vpn-disconnected"}
EOF
fi
