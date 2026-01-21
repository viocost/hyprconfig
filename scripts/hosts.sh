$()$(
  bash
  #!/bin/bash

  HOSTS_FILE="/etc/hosts"
  TEMP_HOSTS="/tmp/hosts.tmp"

  # Generate list, skipping empty/comment-only/localhost/IPv6 lines, prefixing with [ ] or [✓],
  # then sort alphabetically by the second field (domain) and remove duplicates.
  generate_menu() {
    while read -r line; do
      if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*#[[:space:]]*$ &&
        ! "$line" =~ localhost && ! "$line" =~ : ]]; then
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
          clean_line=$(sed 's/^[[:space:]]*#[[:space:]]*//' <<<"$line")
          echo "[ ] $clean_line"
        else
          clean_line=$(sed 's/^[[:space:]]*//' <<<"$line")
          echo "[✓] $clean_line"
        fi
      fi
    done <"$HOSTS_FILE" | sort -k2 -u
  }

  # Toggle comment state of the selected entry
  toggle_entry() {
    local entry="$1"
    # Remove the leading [ ] or [✓] portion
    entry="${entry#*\] }"

    cp "$HOSTS_FILE" "$TEMP_HOSTS"

    if grep -q "^[[:space:]]*#.*$entry" "$TEMP_HOSTS"; then
      sed -i -E "s/^[[:space:]]*#[[:space:]]*($entry)/\1/" "$TEMP_HOSTS"
    else
      sed -i -E "s/^[[:space:]]*($entry)/# \1/" "$TEMP_HOSTS"
    fi

    sudo cp "$TEMP_HOSTS" "$HOSTS_FILE"
    rm "$TEMP_HOSTS"
  }

  # Show Rofi menu with custom keybindings
  show_menu() {
    generate_menu | rofi \
      -dmenu \
      -i \
      -no-custom \
      -kb-custom-1 "space" \
      -kb-accept-entry "Return" \
      -kb-accept-custom "Control+Return" \
      -kb-accept-alt "Alt+Return" \
      -mesg "Space: toggle, Enter: exit" \
      -p "Hosts"
  }

  # Main loop for toggling or exiting
  while true; do
    choice=$(show_menu)
    exit_code=$?

    case $exit_code in
    1) # Escape
      break
      ;;
    10) # Space pressed
      toggle_entry "$choice"
      ;;
    0) # Enter
      break
      ;;
    esac
  done
)$()
