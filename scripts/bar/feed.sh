#!/bin/env bash
#

FEED=$(head -n 1 ~/.feed 2>/dev/null)

[[ $FEED ]] && echo $FEED || echo "<span foreground=\"#777\">FEED DATA NOT AVAILABLE</span>"
