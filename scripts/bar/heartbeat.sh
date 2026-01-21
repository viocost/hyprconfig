#!/bin/bash

RES=$(ping -w 1 -c 1 8.8.8.8 | grep "64 bytes from 8.8.8.8"  | sed -E 's/(.*)(time=)(.*)(\ ms)/\3/')

TRESHOLD_MID=150
TRESHOLD_HI=500

if [ -n "$RES" ]; then
    if [ "$(awk 'BEGIN {print ('$RES' > '$TRESHOLD_HI')}')" -eq 1 ]; then
        echo "<span foreground=\"#9e0000\">  </span><span>${RES} ms </span>"

    elif [ "$(awk 'BEGIN {print ('$RES' > '$TRESHOLD_MID')}')" -eq 1 ]; then
        echo "<span foreground=\"#ffd700\">  </span><span>${RES} ms </span>"

    else
        echo "<span foreground=\"#32a852\">  </span><span>${RES} ms </span>"

    fi

else
    echo "<span foreground=\"#b30404\"> 󰋔 </span><span>T/o </span>"
fi
