#!/usr/bin/env bash
#
# security-scan — thin wrapper around AIDE + `pacman -Qkk`
#
# Detection is delegated to mature tools:
#   * AIDE          — file-integrity of systemd units, cron, PATH binaries,
#                     login/loader persistence, accounts (see aide.conf).
#   * pacman -Qkk   — verifies packaged files against the vendor's checksums,
#                     catching tampering that predates the AIDE baseline.
#
# The wrapper only orchestrates: run both, merge into one report, prune old
# reports, and raise a swaync desktop notification (with Copy/Open actions)
# when something deviates.
#
# Commands:
#   security-scan init     Build/refresh the trusted baseline (AIDE db + pacman).
#   security-scan scan     Run both checks, write a report, notify on findings.
#   security-scan update   Alias for `init` — accept the current state as good.
#   security-scan notify   Internal: emit the desktop notification (runs as user).
#   security-scan help
#
# Exit status of `scan`: 0 = clean, 1 = deviations found, 2 = tool error.

set -o pipefail

# ---------------------------------------------------------------------------
# Paths and defaults (overridable by /etc/security-scanner/scanner.conf)
# ---------------------------------------------------------------------------
SELF="$(readlink -f "$0")"
CONFIG_FILE="/etc/security-scanner/scanner.conf"

STATE_DIR="/var/lib/security-scanner"
AIDE_DB="${STATE_DIR}/aide.db.gz"
AIDE_DB_NEW="${STATE_DIR}/aide.db.new.gz"
PACMAN_BASELINE="${STATE_DIR}/pacman-qkk.baseline"
STATUS_FILE="${STATE_DIR}/last-status"

# Defaults mirrored from scanner.conf so the script works even without it.
RUN_AIDE=1
RUN_PACMAN=1
AIDE_CONFIG="/etc/security-scanner/aide.conf"
NOTIFY_ENABLED=1
NOTIFY_USER=""
NOTIFY_ON_CLEAN=0
NOTIFY_COPY_MODE="path"
NOTIFY_OPEN_CMD="kitty -e nvim {}"
REPORT_DIR="/var/log/security-scanner/reports"
REPORT_KEEP=30

# ---------------------------------------------------------------------------
# Output helpers (plain text when not a TTY, e.g. under the systemd timer)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  c_reset=$'\033[0m'; c_red=$'\033[31m'; c_grn=$'\033[32m'
  c_yel=$'\033[33m'; c_blu=$'\033[34m'; c_bold=$'\033[1m'
else
  c_reset=''; c_red=''; c_grn=''; c_yel=''; c_blu=''; c_bold=''
fi
info() { printf '%s[*]%s %s\n' "$c_blu" "$c_reset" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$c_grn" "$c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_yel" "$c_reset" "$*"; }
err()  { printf '%s[x]%s %s\n' "$c_red" "$c_reset" "$*" >&2; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Must run as root (use sudo)."
    exit 2
  fi
}

# Source scanner.conf only if it is root-owned and not writable by others.
# This mirrors sudo's refusal to read a tamperable config: since root sources
# it, a user-writable config would be a privilege-escalation vector.
load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 0
  local owner perms
  owner="$(stat -c '%u' "$CONFIG_FILE")"
  perms="$(stat -c '%a' "$CONFIG_FILE")"
  if [[ "$owner" != "0" ]]; then
    err "Refusing to source ${CONFIG_FILE}: not owned by root."
    exit 2
  fi
  # Reject any group/other write bit (octal mask 022). Force octal on both
  # operands — inside $(( )) a bare 022 is read as decimal, not octal.
  if (( (8#$perms) & (8#022) )); then
    err "Refusing to source ${CONFIG_FILE}: writable by group/other (mode ${perms})."
    exit 2
  fi
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
}

resolve_notify_user() {
  # Fall back to the sudo invoker or the aide.conf home owner if unset.
  [[ -z "$NOTIFY_USER" ]] && NOTIFY_USER="${SUDO_USER:-}"
  NOTIFY_UID="$(id -u "$NOTIFY_USER" 2>/dev/null)"
  NOTIFY_GID="$(id -g "$NOTIFY_USER" 2>/dev/null)"
}

# ---------------------------------------------------------------------------
# Collectors
# ---------------------------------------------------------------------------

# pacman vendor-checksum warnings (stable, sorted). Root avoids the spurious
# "Permission denied" / "failed to calculate checksum" warnings seen as user.
collect_pacman() {
  LC_ALL=C pacman -Qkk 2>&1 | grep -E '^warning:' | LC_ALL=C sort -u
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_init() {
  require_root
  load_config
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"

  if [[ "$RUN_AIDE" == "1" ]]; then
    info "Building AIDE baseline (this can take a minute)…"
    if aide --config="$AIDE_CONFIG" --init; then
      mv -f "$AIDE_DB_NEW" "$AIDE_DB"
      chmod 600 "$AIDE_DB"
      ok "AIDE baseline written to ${AIDE_DB}"
    else
      err "aide --init failed."
      exit 2
    fi
  fi

  if [[ "$RUN_PACMAN" == "1" ]]; then
    info "Capturing pacman -Qkk baseline…"
    collect_pacman > "$PACMAN_BASELINE"
    chmod 600 "$PACMAN_BASELINE"
    ok "pacman baseline written ($(wc -l < "$PACMAN_BASELINE") known warnings)."
  fi

  printf 'baselined %s\n' "$(date -Is)" > "$STATUS_FILE"
  ok "Baseline complete. Re-run 'init' after any intentional change."
}

cmd_scan() {
  require_root
  load_config
  resolve_notify_user
  mkdir -p "$REPORT_DIR"

  local stamp report tmp
  stamp="$(date +%Y-%m-%d_%H%M%S)"
  report="${REPORT_DIR}/scan-${stamp}.txt"
  tmp="$(mktemp)"

  local changed=0 errored=0
  local aide_status="skipped" pacman_status="skipped"

  {
    printf 'Security scan — %s\n' "$(date)"
    printf 'Host: %s\n' "$(hostname)"
    printf '================================================================\n\n'
  } >> "$tmp"

  # ---- AIDE -------------------------------------------------------------
  if [[ "$RUN_AIDE" == "1" ]]; then
    if [[ ! -f "$AIDE_DB" ]]; then
      warn "No AIDE baseline — run 'security-scan init' first."
      printf '[AIDE] NO BASELINE — run: security-scan init\n\n' >> "$tmp"
      aide_status="no-baseline"; errored=1
    else
      local aide_out aide_rc
      aide_out="$(aide --config="$AIDE_CONFIG" --check 2>&1)"; aide_rc=$?
      if [[ $aide_rc -eq 0 ]]; then
        aide_status="clean"
        printf '[AIDE] clean — no file-integrity changes.\n\n' >> "$tmp"
      elif [[ $aide_rc -ge 1 && $aide_rc -le 7 ]]; then
        aide_status="CHANGES"; changed=1
        printf '[AIDE] CHANGES DETECTED (code %d)\n' "$aide_rc" >> "$tmp"
        printf '%s\n\n' "$aide_out" >> "$tmp"
      else
        aide_status="ERROR"; errored=1
        printf '[AIDE] ERROR (code %d)\n%s\n\n' "$aide_rc" "$aide_out" >> "$tmp"
      fi
    fi
  fi

  # ---- pacman -Qkk ------------------------------------------------------
  if [[ "$RUN_PACMAN" == "1" ]]; then
    if [[ ! -f "$PACMAN_BASELINE" ]]; then
      printf '[pacman -Qkk] NO BASELINE — run: security-scan init\n\n' >> "$tmp"
      pacman_status="no-baseline"; errored=1
    else
      local cur new
      cur="$(mktemp)"; collect_pacman > "$cur"
      new="$(LC_ALL=C comm -13 "$PACMAN_BASELINE" "$cur")"
      if [[ -z "$new" ]]; then
        pacman_status="clean"
        printf '[pacman -Qkk] clean — no new checksum mismatches.\n\n' >> "$tmp"
      else
        pacman_status="CHANGES"; changed=1
        printf '[pacman -Qkk] NEW MISMATCHES since baseline:\n' >> "$tmp"
        printf '%s\n\n' "$new" >> "$tmp"
      fi
      rm -f "$cur"
    fi
  fi

  # ---- Result line ------------------------------------------------------
  local result
  if [[ $changed -eq 1 ]]; then
    result="CHANGES DETECTED"
  elif [[ $errored -eq 1 ]]; then
    result="ERROR / INCOMPLETE"
  else
    result="CLEAN"
  fi
  {
    printf '================================================================\n'
    printf 'RESULT: %s   (aide=%s, pacman=%s)\n' "$result" "$aide_status" "$pacman_status"
  } >> "$tmp"

  # ---- Persist report (readable by the notify user) ---------------------
  install -m 640 "$tmp" "$report"
  if [[ -n "$NOTIFY_USER" ]]; then
    chown "root:${NOTIFY_USER}" "$report" 2>/dev/null || true
    chown "root:${NOTIFY_USER}" "$REPORT_DIR" 2>/dev/null || true
    chmod 750 "$REPORT_DIR"
  fi
  rm -f "$tmp"
  prune_reports
  printf '%s %s\n' "$(date -Is)" "$result" > "$STATUS_FILE"

  # ---- Console summary --------------------------------------------------
  if [[ $changed -eq 1 ]]; then
    warn "$result — aide=${aide_status}, pacman=${pacman_status}"
  elif [[ $errored -eq 1 ]]; then
    err "$result — aide=${aide_status}, pacman=${pacman_status}"
  else
    ok "$result"
  fi
  info "Report: ${report}"

  # ---- Notify -----------------------------------------------------------
  if [[ "$NOTIFY_ENABLED" == "1" ]]; then
    if [[ $changed -eq 1 || $errored -eq 1 ]]; then
      dispatch_notification "$report" "changes"
    elif [[ "$NOTIFY_ON_CLEAN" == "1" ]]; then
      dispatch_notification "$report" "clean"
    fi
  fi

  [[ $changed -eq 1 || $errored -eq 1 ]] && return 1
  return 0
}

prune_reports() {
  [[ "${REPORT_KEEP:-0}" -gt 0 ]] || return 0
  ls -1t "$REPORT_DIR"/scan-*.txt 2>/dev/null \
    | tail -n +$((REPORT_KEEP + 1)) \
    | xargs -r rm -f
}

# Launch the notifier inside the target user's session (independent transient
# scope so it survives this root service exiting) with the env notify-send and
# wl-copy need. Skips silently if the user has no live session bus (e.g. boot
# before login) — the report is still on disk.
dispatch_notification() {
  local report="$1" status="$2"
  [[ -n "$NOTIFY_UID" ]] || { warn "notify: unknown user, skipping."; return; }
  local bus="/run/user/${NOTIFY_UID}/bus"
  if [[ ! -S "$bus" ]]; then
    info "notify: no session bus for ${NOTIFY_USER}, skipping (report saved)."
    return
  fi
  # Fire-and-forget transient service (NOT --scope, which would block this root
  # scan on notify-send --wait). Runs independently of our cgroup and survives.
  systemd-run \
    --uid="$NOTIFY_UID" --gid="$NOTIFY_GID" \
    --setenv=XDG_RUNTIME_DIR="/run/user/${NOTIFY_UID}" \
    --setenv=DBUS_SESSION_BUS_ADDRESS="unix:path=${bus}" \
    --setenv=SCANNER_COPY_MODE="$NOTIFY_COPY_MODE" \
    --setenv=SCANNER_OPEN_CMD="$NOTIFY_OPEN_CMD" \
    --collect --quiet \
    "$SELF" notify "$status" "$report" 2>/dev/null \
    || warn "notify: failed to dispatch to ${NOTIFY_USER}."
}

# Runs AS THE USER (no root). Shows the notification and handles the actions.
cmd_notify() {
  local status="$1" report="$2"
  local copy_mode="${SCANNER_COPY_MODE:-path}"
  local open_cmd="${SCANNER_OPEN_CMD:-kitty -e nvim {}}"

  local title body urgency icon
  if [[ "$status" == "clean" ]]; then
    title="Security scan: clean"
    body="No integrity changes.\n${report}"
    urgency="low"; icon="security-high"
  else
    title="Security scan: changes detected"
    body="Deviations found — review the report.\n${report}"
    urgency="critical"; icon="dialog-warning"
  fi

  local action
  action="$(notify-send \
      --app-name="Security Scanner" \
      --urgency="$urgency" \
      --icon="$icon" \
      --action="open=Open report" \
      --action="copy=Copy path" \
      --wait \
      "$title" "$body" 2>/dev/null)"

  case "$action" in
    open)
      # {} placeholder -> report path.
      local cmd="${open_cmd//\{\}/$report}"
      setsid -f bash -c "$cmd" >/dev/null 2>&1 || true
      ;;
    copy)
      if [[ "$copy_mode" == "content" && -r "$report" ]]; then
        wl-copy < "$report"
      else
        printf '%s' "$report" | wl-copy
      fi
      ;;
  esac
}

cmd_help() {
  cat <<EOF
${c_bold}security-scan${c_reset} — AIDE + pacman -Qkk integrity wrapper

Usage:
  sudo security-scan init      Build/refresh the trusted baseline.
  sudo security-scan scan      Run checks, write report, notify on findings.
  sudo security-scan update    Alias for 'init' (accept current state).
       security-scan help

Config:    ${CONFIG_FILE}
AIDE conf: ${AIDE_CONFIG}
State:     ${STATE_DIR}
Reports:   ${REPORT_DIR}

After any intentional change (new service, edited cron, package update),
re-run 'sudo security-scan init' so the change becomes the trusted baseline.
EOF
}

main() {
  case "${1:-help}" in
    init)          cmd_init ;;
    scan|check)    cmd_scan ;;
    update)        cmd_init ;;
    notify)        shift; cmd_notify "$@" ;;
    help|-h|--help) cmd_help ;;
    *) err "Unknown command: $1"; echo; cmd_help; exit 2 ;;
  esac
}

main "$@"
