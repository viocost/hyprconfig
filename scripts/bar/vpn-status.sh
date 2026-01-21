#!/bin/bash
if pgrep -x openvpn >/dev/null 2>/dev/null; then 
	echo "<span foreground=\"#d14d02\">  VPN</span>"
else
	echo "<span foreground=\"#555\"><s>VPN</s></span>"
fi
