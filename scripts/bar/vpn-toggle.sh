#!/bin/bash

if pgrep -x openvpn >/dev/null 2>/dev/null; then
	sudo killall openvpn
else
	sudo openvpn --config ${VPN_CONFIG} &
fi
