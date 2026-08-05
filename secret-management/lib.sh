#!/usr/bin/env bash
# Shared helpers for the secret-management scripts (rotate.sh / validate.sh).
# This file is meant to be *sourced*, not executed directly.
#
# The secret pipeline mirrors what install/git.sh expects on extraction:
#   steghide extract -sf <image>   ->   dev_key.gpg
#   gpg dev_key.gpg                 ->   dev_key   (an OpenSSH private key)
#
# A single passphrase protects both the GPG layer and the steghide layer. It is
# read interactively, passed to gpg via a file descriptor and to steghide via a
# PTY helper, so it never lands in argv / shell history / /proc/<pid>/cmdline.

# Directory containing this library and ptyfeed.py.
SM_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SM_PTYFEED="$SM_LIB_DIR/ptyfeed.py"

sm_die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
sm_info() { printf '%s\n' "$*" >&2; }

# sm_require_cmd CMD...   -- abort if any command is missing.
sm_require_cmd() {
  local c missing=()
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
  done
  [ ${#missing[@]} -eq 0 ] || sm_die "missing required command(s): ${missing[*]}"
}

# sm_make_workdir   -- create a private temp dir (SM_WORKDIR) + cleanup trap.
sm_make_workdir() {
  SM_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/secret-mgmt.XXXXXX")" || sm_die "mktemp failed"
  chmod 700 "$SM_WORKDIR"
  trap sm_cleanup EXIT INT TERM
}

# sm_cleanup   -- shred every file under SM_WORKDIR, then remove it.
sm_cleanup() {
  [ -n "${SM_WORKDIR:-}" ] && [ -d "${SM_WORKDIR:-}" ] || return 0
  if command -v shred >/dev/null 2>&1; then
    find "$SM_WORKDIR" -type f -exec shred -u {} + 2>/dev/null || true
  fi
  rm -rf "$SM_WORKDIR" 2>/dev/null || true
}

# sm_read_passphrase PROMPT   -- read (no echo) into global SM_PASSPHRASE.
sm_read_passphrase() {
  local prompt="$1" pp
  IFS= read -r -s -p "$prompt" pp < /dev/tty || sm_die "could not read passphrase from terminal"
  printf '\n' >&2
  SM_PASSPHRASE="$pp"
}

# sm_read_passphrase_confirm   -- read twice, require non-empty + matching.
sm_read_passphrase_confirm() {
  local a b
  while :; do
    sm_read_passphrase "Enter passphrase (paste): "; a="$SM_PASSPHRASE"
    [ -n "$a" ] || { sm_info "passphrase must not be empty."; continue; }
    sm_read_passphrase "Re-enter passphrase:      "; b="$SM_PASSPHRASE"
    [ "$a" = "$b" ] && { SM_PASSPHRASE="$a"; break; }
    sm_info "passphrases did not match; try again."
  done
}

# sm_gpg_encrypt INFILE OUTFILE PASS   -- symmetric (passphrase) encryption.
sm_gpg_encrypt() {
  local in="$1" out="$2" pass="$3"
  gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 3 \
      -c --cipher-algo AES256 --s2k-mode 3 --s2k-digest-algo SHA512 \
      --s2k-count 65011712 -o "$out" "$in" 3<<<"$pass"
}

# sm_gpg_decrypt INFILE OUTFILE PASS
sm_gpg_decrypt() {
  local in="$1" out="$2" pass="$3"
  gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 3 \
      -o "$out" --decrypt "$in" 3<<<"$pass"
}

# sm_steghide_embed COVER EMBEDFILE STEGO_OUT PASS
sm_steghide_embed() {
  local cover="$1" ef="$2" sf="$3" pass="$4"
  if command -v python3 >/dev/null 2>&1 && [ -f "$SM_PTYFEED" ]; then
    SM_PP="$pass" python3 "$SM_PTYFEED" 2 \
      steghide embed -cf "$cover" -ef "$ef" -sf "$sf" -f
  else
    sm_info "python3/ptyfeed unavailable; steghide will prompt — paste the SAME passphrase (twice)."
    steghide embed -cf "$cover" -ef "$ef" -sf "$sf" -f < /dev/tty
  fi
}

# sm_steghide_extract STEGO OUTDIR PASS
# Extracts using the *embedded* filename (as install/git.sh does) into OUTDIR.
sm_steghide_extract() {
  local sf out pass
  sf="$(cd -- "$(dirname -- "$1")" && pwd)/$(basename -- "$1")"   # absolutise
  out="$2"; pass="$3"
  if command -v python3 >/dev/null 2>&1 && [ -f "$SM_PTYFEED" ]; then
    ( cd "$out" && SM_PP="$pass" python3 "$SM_PTYFEED" 1 \
        steghide extract -sf "$sf" -f )
  else
    sm_info "python3/ptyfeed unavailable; steghide will prompt — paste the SAME passphrase."
    ( cd "$out" && steghide extract -sf "$sf" -f < /dev/tty )
  fi
}

# sm_key_fingerprint KEYFILE   -- print SHA256 fingerprint (or "(unknown)").
sm_key_fingerprint() {
  ssh-keygen -lf "$1" 2>/dev/null | awk '{print $2}' || printf '(unknown)'
}

# sm_key_pub KEYFILE   -- print "type base64" of the public half (no comment),
# returns non-zero if the key is invalid or passphrase-protected.
sm_key_pub() {
  ssh-keygen -y -P '' -f "$1" 2>/dev/null | awk '{print $1" "$2}'
}
