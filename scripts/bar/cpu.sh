#!/bin/env bash

TEMP_FULL=$(sensors | grep "Core 0" | awk '{print $3}' | sed -r 's/[^0-9\.]//g')
TEMP=$( printf "%.0f" $TEMP_FULL 2>/dev/null)

 # 
 #  
 #   


if [ $TEMP -le 72 ]; then
         echo "<span foreground=\"#01c64d\">  $TEMP°C</span>"
elif [ $TEMP -le 82 ]; then
         echo "<span foreground=\"#FFFC00\">  $TEMP°C</span>"

elif [ $TEMP -le 90 ]; then
         echo "<span foreground=\"#e57504\">  $TEMP°C</span>"
else
         echo "<span foreground=\"#e50404\">  $TEMP°C</span>"
fi

exit 0
