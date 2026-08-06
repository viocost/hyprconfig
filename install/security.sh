#!/bin/bash
#
# install/security.sh — deploy the AIDE + pacman -Qkk integrity scanner.
#
# Installs AIDE, deploys the wrapper/config/units, builds the trusted baseline,
# and enables the boot + 3h timer. Idempotent: safe to re-run.

set -euo pipefail

# Resolve repo root (this file lives in <repo>/install/).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SRC="${REPO_DIR}/security/scanner"

# Run privileged steps via sudo unless we are already root.
SUDO="sudo"
[[ $EUID -eq 0 ]] && SUDO=""

# The GUI user the scanner notifies (the human running the install).
TARGET_USER="${SUDO_USER:-$USER}"
[[ "$TARGET_USER" == "root" ]] && TARGET_USER="$(logname 2>/dev/null || echo root)"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "=========================================="
echo "  Security Scanner (AIDE + pacman -Qkk)"
echo "=========================================="
echo "  user: ${TARGET_USER}   home: ${TARGET_HOME}"
echo ""

# --- 1. Dependencies -------------------------------------------------------
echo "📦 Ensuring dependencies (aide, libnotify, wl-clipboard)…"
if ! $SUDO pacman -S --needed --noconfirm aide libnotify wl-clipboard; then
  echo "   sync db may be stale — refreshing and retrying…"
  $SUDO pacman -Sy --noconfirm
  $SUDO pacman -S --needed --noconfirm aide libnotify wl-clipboard
fi

# --- 2. Directories --------------------------------------------------------
echo "📁 Creating directories…"
$SUDO install -d -m 755 /etc/security-scanner
$SUDO install -d -m 700 /var/lib/security-scanner
$SUDO install -d -m 750 /var/log/security-scanner/reports
$SUDO chown "root:${TARGET_USER}" /var/log/security-scanner/reports

# --- 3. Deploy wrapper, configs, units (templating the user/home) ----------
echo "🚀 Installing wrapper → /usr/local/bin/security-scan"
$SUDO install -m 755 -o root -g root "${SRC}/security-scan.sh" /usr/local/bin/security-scan

echo "🧩 Installing AIDE policy → /etc/security-scanner/aide.conf"
tmp_aide="$(mktemp)"
sed -e "s#/home/kostia#${TARGET_HOME}#g" "${SRC}/config/aide.conf" > "$tmp_aide"
$SUDO install -m 644 -o root -g root "$tmp_aide" /etc/security-scanner/aide.conf
rm -f "$tmp_aide"

echo "🔧 Installing wrapper config → /etc/security-scanner/scanner.conf"
if [[ -f /etc/security-scanner/scanner.conf ]]; then
  echo "   exists — leaving your scanner.conf untouched."
else
  tmp_cfg="$(mktemp)"
  sed -e "s#kostia#${TARGET_USER}#g" "${SRC}/config/scanner.conf" > "$tmp_cfg"
  $SUDO install -m 600 -o root -g root "$tmp_cfg" /etc/security-scanner/scanner.conf
  rm -f "$tmp_cfg"
fi

echo "⏱️  Installing systemd units…"
tmp_svc="$(mktemp)"
sed -e "s#kostia#${TARGET_USER}#g" \
    -e "s#/home/kostia#${TARGET_HOME}#g" "${SRC}/systemd/security-scan.service" > "$tmp_svc"
$SUDO install -m 644 -o root -g root "$tmp_svc" /etc/systemd/system/security-scan.service
rm -f "$tmp_svc"
$SUDO install -m 644 -o root -g root "${SRC}/systemd/security-scan.timer" /etc/systemd/system/security-scan.timer
$SUDO systemctl daemon-reload

# --- 4. Build the trusted baseline -----------------------------------------
echo ""
echo "🔐 Building the initial baseline."
echo "   IMPORTANT: only trustworthy if this host is currently clean."
$SUDO security-scan init

# --- 5. Enable the timer ---------------------------------------------------
echo ""
echo "▶️  Enabling security-scan.timer (boot + every 3h)…"
$SUDO systemctl enable --now security-scan.timer

echo ""
echo "=========================================="
echo "  Done."
echo "=========================================="
echo "  Manual scan:   sudo security-scan scan"
echo "  Re-baseline:   sudo security-scan init   (after intended changes)"
echo "  Timer status:  systemctl status security-scan.timer"
echo "  Reports:       /var/log/security-scanner/reports"
echo ""
