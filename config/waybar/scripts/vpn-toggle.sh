#!/bin/bash

if pgrep -x openvpn >/dev/null 2>/dev/null; then
    sudo killall openvpn
    notify-send "VPN" "Disconnected" -u normal
else
    if [ -n "$VPN_CONFIG" ] && [ -f "$VPN_CONFIG" ]; then
        sudo openvpn --config "${VPN_CONFIG}" &
        notify-send "VPN" "Connecting..." -u normal
    else
        notify-send "VPN" "VPN_CONFIG not set or file not found" -u critical
    fi
fi
