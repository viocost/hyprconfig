#!/bin/bash

# 1. Gather existing sessions from /tmp
# We strip the path to show just the name in FZF
existing_sessions=""
if ls /tmp/nvim_*.sock >/dev/null 2>&1; then
    existing_sessions=$(ls /tmp/nvim_*.sock | sed 's|/tmp/nvim_||;s|.sock||;s/\(.*\)/󱓞 \1/')
fi

# 2. Gather directories (Your specific list)
directories=$(find ~/projects ~/hyprconfig/ \
    -mindepth 1 -maxdepth 3 -type d \( -name node_modules -o -name .git \) -prune -o -type d -print | sed 's/\(.*\)/󰉖 \1/')

# 3. Combine and Select
selected=$(echo -e "${existing_sessions}\n${directories}" | grep -v '^$' | fzf --prompt="NVIM Session/Project > ")

[ -z "$selected" ] && exit 0

# 4. Logic: Are we attaching or starting?
icon=$(echo "$selected" | awk '{print $1}')
name=$(echo "$selected" | cut -d' ' -f2-)

if [[ "$icon" == "󱓞" ]]; then
    # ATTACHING to existing
    SOCKET="/tmp/nvim_${name}.sock"
else
    # STARTING new
    # Create a unique socket name by sanitizing the directory path
    CLEAN_NAME=$(echo "$name" | sed 's|/|_|g; s|~|home|g')
    SOCKET="/tmp/nvim_${CLEAN_NAME}.sock"
    
    if [ ! -S "$SOCKET" ]; then
        # Start headless server in the background
        (cd "$name" && nvim --headless --listen "$SOCKET" --cmd "redraw!" .) &
        sleep 0.3
    fi
fi

# 5. Launch UI and Clean up terminal
neovide  --server "$SOCKET" > /dev/null 2>&1 &
if [ -n "$KITTY_PID" ]; then
    kill -9 "$KITTY_PID"
else
    # Fallback for other terminals
    kill -9 $PPID
fi
exit 0
