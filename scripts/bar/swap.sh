#!/usr/bin/env sh
# Copyright (C) 2014 Julien Bonjean <julien@bonjean.info>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

TYPE="${BLOCK_INSTANCE:-mem}"
PERCENT="${PERCENT:-true}"

awk -v type=$TYPE -v percent=$PERCENT '
/^MemTotal:/ {
    mem_total=$2
}
/^MemFree:/ {
    mem_free=$2
}
/^Buffers:/ {
    mem_free+=$2
}
/^Cached:/ {
    mem_free+=$2
}
/^SwapTotal:/ {
    swap_total=$2
}
/^SwapFree:/ {
    swap_free=$2
}
END {
    mem_used=(mem_total-mem_free)/1024/1024
    mem_total_gb=mem_total/1024/1024
    mem_pct=0
    if (mem_total > 0) {
        mem_pct=mem_used/mem_total_gb*100
    }

    swap_used=(swap_total-swap_free)/1024/1024
    swap_total_gb=swap_total/1024/1024
    swap_pct=0
    if (swap_total > 0) {
        swap_pct=swap_used/swap_total_gb*100
    }

    # color based on memory usage
    if (swap_pct > 90) {
        color="#FF0000"
    } else if (swap_pct > 80) {
        color="#FFAE00"
    } else if (swap_pct > 70) {
        color="#FFF600"
    } else {
        color="#01c64d"
    }

    # full text
    if (percent == "true" ) {
        printf("<span foreground=\"#EBDBB2\"> %.1fG / %.1fG</span> <span foreground=\"%s\"> (%.f%%)</span>\n", swap_used, swap_total_gb, color, swap_pct)
    } else {
        printf("%.1fG/%.1fG\n", swap_used, swap_total_gb)
    }

    # short text
    printf("Mem: %.f%%\n", mem_pct)
    printf("Swap: %.f%%\n", swap_pct)
}
' /proc/meminfo
