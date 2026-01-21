#!/bin/bash

# Monitor setup script for NVIDIA hybrid laptop with 3 monitors
# Internal: eDP-1 (1920x1080) - Physical DPI: 141.8
# Full HD via dock: DP-1-4.2 (1920x1080) - Physical DPI: 92.5
# 4K: DP-1-0 (3840x2160) - Physical DPI: 139.3

# REALITY CHECK: True per-monitor DPI scaling via xrandr transform causes overflow
# X11 doesn't support true per-monitor DPI well - it's a global setting
# 
# APPROACH: Use native resolutions + compromise DPI + application scaling
# - All monitors at native resolution (no xrandr scaling/transform)
# - Set DPI to a compromise value (120-140)
# - Use GDK_SCALE for application-level adjustments

# Detect which monitors are connected
INTERNAL="eDP-1"
FULLHD="DP-1-4.2"
FOUREK="DP-1-0"

# Check what's actually connected
INTERNAL_CONNECTED=$(xrandr | grep "^$INTERNAL connected" | wc -l)
FULLHD_CONNECTED=$(xrandr | grep "^$FULLHD connected" | wc -l)
FOUREK_CONNECTED=$(xrandr | grep "^$FOUREK connected" | wc -l)

# Calculate positions
# 4K at 0x0 (3840x2160)
# FullHD after 4K: x = 3840, y = (2160-1080)/2 = 540
# Internal after FullHD: x = 3840 + 1920 = 5760, y = 540

FULLHD_X=3840
FULLHD_Y=540
INTERNAL_X=5760
INTERNAL_Y=540

# Setup based on what's connected - native resolutions only
if [ $FOUREK_CONNECTED -eq 1 ] && [ $FULLHD_CONNECTED -eq 1 ] && [ $INTERNAL_CONNECTED -eq 1 ]; then
    echo "All three monitors detected - using native resolutions"
    echo "4K: 139.3 DPI, FullHD: 92.5 DPI, Internal: 141.8 DPI"
    echo "Using compromise DPI setting for reasonable text across all displays"
    
    # Apply all monitors at native resolution
    xrandr \
        --output $FOUREK --mode 3840x2160 --pos 0x0 --primary \
        --output $FULLHD --mode 1920x1080 --pos ${FULLHD_X}x${FULLHD_Y} \
        --output $INTERNAL --mode 1920x1080 --pos ${INTERNAL_X}x${INTERNAL_Y}
    
elif [ $FOUREK_CONNECTED -eq 1 ] && [ $FULLHD_CONNECTED -eq 1 ]; then
    echo "4K and FullHD monitors detected"
    xrandr \
        --output $FOUREK --mode 3840x2160 --pos 0x0 --primary \
        --output $FULLHD --mode 1920x1080 --pos ${FULLHD_X}x${FULLHD_Y} \
        --output $INTERNAL --off
    
elif [ $FOUREK_CONNECTED -eq 1 ]; then
    echo "Only 4K monitor detected"
    xrandr \
        --output $FOUREK --mode 3840x2160 --pos 0x0 --primary \
        --output $FULLHD --off \
        --output $INTERNAL --off
        
else
    echo "Using internal display only"
    xrandr \
        --output $INTERNAL --mode 1920x1080 --pos 0x0 --primary \
        --output $FULLHD --off \
        --output $FOUREK --off
fi

# Apply DPI settings from Xresources
xrdb -merge ~/.Xresources

echo ""
echo "Monitor setup complete - all at native resolution"
echo "Current framebuffer: $(xrandr | grep "Screen 0" | grep -oP 'current \K[0-9]+ x [0-9]+')"
echo ""
echo "Active monitors:"
xrandr --listactivemonitors
echo ""
echo "NOTE: Text will appear different sizes due to different physical DPIs"
echo "Adjust Xft.dpi in ~/.Xresources and GDK_SCALE in ~/.xprofile for best compromise"
