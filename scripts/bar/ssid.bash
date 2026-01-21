#!/usr/bin/env bash

SSID=$(iwgetid | awk -F ':'   '{print $2}' | sed 's/\"//g')

#------------------------------------------------------------------------

echo "<span foreground=\"#EBDBB2\"><b>$SSID</b></span>" # full text
