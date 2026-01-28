#!/bin/bash

# Cron Jobs Setup Script for hyprconfig
# Sets up automated tasks via crontab

echo "=========================================="
echo "  Cron Jobs Setup"
echo "=========================================="
echo ""

# Check if cronie service is enabled
if ! systemctl is-enabled cronie.service &>/dev/null; then
  echo "⚠️  Warning: cronie.service is not enabled"
  echo "   Run: sudo systemctl enable --now cronie.service"
  echo ""
fi

# Backup existing crontab
CRONTAB_BACKUP="$HOME/.crontab.backup.$(date +%Y%m%d_%H%M%S)"
if crontab -l &>/dev/null; then
  echo "📋 Backing up existing crontab to: $CRONTAB_BACKUP"
  crontab -l > "$CRONTAB_BACKUP"
fi

# Define cron jobs
# Using $HOME instead of hardcoded paths for portability
CRON_JOBS=(
  "# Feed generation for waybar - runs every minute"
  "*/1 * * * * \$HOME/.local/bin/scripts/bar/generate_feed.py \$HOME/.feed"
  ""
  "# Knowledge base commit - runs every 5 minutes"
  "*/5 * * * * \$HOME/.local/bin/scripts/bar/commit_kb.sh"
)

# Create temporary crontab file
TEMP_CRONTAB="/tmp/hyprconfig_crontab_$$"

# Start with existing crontab (if any) or empty
if crontab -l &>/dev/null; then
  crontab -l > "$TEMP_CRONTAB"
  echo "" >> "$TEMP_CRONTAB"
  echo "# === hyprconfig automated jobs ===" >> "$TEMP_CRONTAB"
else
  echo "# === hyprconfig automated jobs ===" > "$TEMP_CRONTAB"
fi

# Add each cron job
for job in "${CRON_JOBS[@]}"; do
  echo "$job" >> "$TEMP_CRONTAB"
done

# Show what will be added
echo "📝 Cron jobs to be added:"
echo ""
for job in "${CRON_JOBS[@]}"; do
  if [[ ! "$job" =~ ^#.*$ ]] && [[ -n "$job" ]]; then
    echo "   $job"
  fi
done
echo ""

# Ask for confirmation
read -p "Install these cron jobs? (y/N): " answer

if [[ "${answer,,}" =~ ^y(es)?$ ]]; then
  # Install the new crontab
  if crontab "$TEMP_CRONTAB"; then
    echo "✓ Cron jobs installed successfully"
    
    # Verify installation
    echo ""
    echo "📋 Current crontab:"
    crontab -l | grep -v "^#" | grep -v "^$" || echo "   (no active jobs)"
  else
    echo "❌ Failed to install cron jobs"
    if [ -f "$CRONTAB_BACKUP" ]; then
      echo "   Backup available at: $CRONTAB_BACKUP"
    fi
    rm -f "$TEMP_CRONTAB"
    exit 1
  fi
else
  echo "Skipping cron job installation..."
  rm -f "$TEMP_CRONTAB"
  exit 0
fi

# Cleanup
rm -f "$TEMP_CRONTAB"

echo ""
echo "=========================================="
echo "  Cron Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Installed Jobs:"
echo "  • Feed generation - Every 1 minute"
echo "  • KB commit - Every 5 minutes"
echo ""
echo "💡 Useful Commands:"
echo "  • View crontab:   crontab -l"
echo "  • Edit crontab:   crontab -e"
echo "  • Remove crontab: crontab -r"
echo "  • Check logs:     journalctl -u cronie -f"
echo ""

# Check if cronie is running
if systemctl is-active cronie.service &>/dev/null; then
  echo "✓ cronie service is running"
else
  echo "⚠️  cronie service is NOT running"
  echo "   Start it with: sudo systemctl start cronie.service"
fi

echo ""
