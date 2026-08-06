#!/bin/bash

# Services setup script for hyprconfig
# Enables and configures systemd services

# Generic function to enable a systemd service
# Usage: enable_service <service_name> <display_name> <emoji> [user] [start_now]
enable_service() {
  local service_name="$1"
  local display_name="$2"
  local emoji="$3"
  local user_mode="${4:-false}"
  local start_now="${5:-false}"

  local systemctl_cmd="systemctl"
  local enable_flags="enable"

  if [[ "$user_mode" == "true" ]]; then
    systemctl_cmd="systemctl --user"
  else
    systemctl_cmd="sudo systemctl"
  fi

  if [[ "$start_now" == "true" ]]; then
    enable_flags="enable --now"
  fi

  # Check if service exists
  if $systemctl_cmd list-unit-files 2>/dev/null | grep -q "${service_name}"; then
    echo "${emoji} Enabling ${display_name}..."

    if $systemctl_cmd $enable_flags "${service_name}"; then
      if [[ "$start_now" == "true" ]]; then
        echo "✓ ${display_name} enabled and started"
      else
        echo "✓ ${display_name} enabled (will start on boot)"
      fi
      return 0
    else
      echo "❌ Failed to enable ${display_name}"
      return 1
    fi
  else
    echo "⚠️  ${display_name} service not found, skipping..."
    return 2
  fi
}

echo "=========================================="
echo "  System Services Setup"
echo "=========================================="
echo ""

# Track enabled services for summary
ENABLED_SERVICES=()

# System services (enabled but not started)
if enable_service "NetworkManager.service" "NetworkManager" "🌐" false false; then
  ENABLED_SERVICES+=("NetworkManager - Network management")
fi

if enable_service "cronie.service" "Cronie" "⏰" false false; then
  ENABLED_SERVICES+=("cronie - Cron job scheduler")
fi

# NOTE: hyprland-autoname-workspaces is intentionally NOT enabled as a systemd
# user service. It is launched via `exec-once` in hypr/hyprland.conf with the
# custom `--config ~/.config/hypr/hyprland-autoname-workspaces.toml`. Enabling
# the systemd unit too caused a double-start ("already running, exit") and the
# unit ignores the custom config (no --config in its ExecStart).

# Summary
echo ""
echo "=========================================="
echo "  Services Setup Complete!"
echo "=========================================="
echo ""

if [ ${#ENABLED_SERVICES[@]} -gt 0 ]; then
  echo "📋 Enabled Services:"
  for service in "${ENABLED_SERVICES[@]}"; do
    echo "  • $service"
  done
  echo ""
  echo "Note: System services are enabled but not started."
  echo "They will start automatically on next boot."
  echo "User services are started immediately."
else
  echo "⚠️  No services were enabled."
fi

echo ""
