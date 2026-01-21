#!/bin/bash

echo "Reloading X resources and restarting i3..."

# Reload Xresources
xrdb -merge ~/.Xresources

# Restart i3 in place (preserves your session)
i3-msg restart

echo "Done! Your monitors should now be properly scaled."
echo ""
echo "Note: Some applications (like terminals) may need to be restarted to pick up the new scaling."
echo "If fonts are still too small/large, you can adjust:"
echo "  - GDK_SCALE in ~/.xprofile (currently 1.5)"
echo "  - Xft.dpi in ~/.Xresources (currently 144)"
