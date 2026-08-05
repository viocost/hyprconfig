#!/usr/bin/env bash
#
# validate.sh -- verify that an image carries the rotated secret and decrypts
# exactly the way install/git.sh expects:
#
#     steghide extract -sf <image>   ->   dev_key.gpg
#     gpg dev_key.gpg                 ->   dev_key  (a valid OpenSSH private key)
#
# Usage:
#     ./validate.sh --target <path-to-image> [--ssh-key <expected-private-key>]
#
# With --ssh-key it also confirms the recovered key equals the one you expect.
# Exit status is 0 on success, non-zero on any failure (safe to script).
#
set -euo pipefail

SM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SM_DIR/lib.sh"

usage() {
  cat >&2 <<EOF
Validate that an image decrypts as install/git.sh expects.

Usage:
  ${0##*/} --target <path-to-image> [--ssh-key <expected-private-key>]

Options:
  --target  <path>   Image to check.
  --ssh-key <path>   Optional: compare the recovered key against this one.
  -h, --help         Show this help.

Exit status: 0 = valid, non-zero = failure.
EOF
}

TARGET=""; SSH_KEY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)  TARGET="${2:-}";  shift 2 || sm_die "--target needs a value" ;;
    --ssh-key) SSH_KEY="${2:-}"; shift 2 || sm_die "--ssh-key needs a value" ;;
    -h|--help) usage; exit 0 ;;
    *) usage; sm_die "unknown argument: $1" ;;
  esac
done

[ -n "$TARGET" ] || { usage; sm_die "--target is required"; }

sm_require_cmd gpg steghide ssh-keygen mktemp
[ -f "$TARGET" ] || sm_die "target image not found: $TARGET"
[ -r "$TARGET" ] || sm_die "target image not readable: $TARGET"
[ -z "$SSH_KEY" ] || [ -r "$SSH_KEY" ] || sm_die "expected ssh key not readable: $SSH_KEY"

sm_make_workdir
xdir="$SM_WORKDIR/x"; mkdir -p "$xdir"

sm_read_passphrase "Enter passphrase (paste): "
pass="$SM_PASSPHRASE"

sm_info "[1/4] steghide extract..."
sm_steghide_extract "$TARGET" "$xdir" "$pass" \
  || sm_die "FAIL: steghide could not extract (wrong passphrase, wrong image, or no payload)."
[ -f "$xdir/dev_key.gpg" ] \
  || sm_die "FAIL: extracted file is not named 'dev_key.gpg' (install/git.sh expects that name)."
sm_info "      -> recovered dev_key.gpg"

sm_info "[2/4] gpg decrypt..."
sm_gpg_decrypt "$xdir/dev_key.gpg" "$xdir/dev_key" "$pass" \
  || sm_die "FAIL: gpg decryption failed (wrong passphrase?)."
chmod 600 "$xdir/dev_key"

sm_info "[3/4] validate OpenSSH private key..."
rec_pub="$(sm_key_pub "$xdir/dev_key")" \
  || sm_die "FAIL: decrypted data is not a valid, unprotected OpenSSH private key."
sm_info "      -> valid key, fingerprint: $(sm_key_fingerprint "$xdir/dev_key")"

sm_info "[4/4] compare to expected key..."
if [ -n "$SSH_KEY" ]; then
  cp -- "$SSH_KEY" "$SM_WORKDIR/expected"; chmod 600 "$SM_WORKDIR/expected"
  exp_pub="$(sm_key_pub "$SM_WORKDIR/expected")" \
    || sm_die "FAIL: could not read --ssh-key '$SSH_KEY' (passphrase-protected or invalid)."
  [ "$rec_pub" = "$exp_pub" ] \
    || sm_die "FAIL: recovered key does NOT match --ssh-key."
  sm_info "      -> MATCH: recovered key equals --ssh-key"
else
  sm_info "      -> skipped (no --ssh-key given)"
fi

sm_info ""
sm_info "OK: '$TARGET' is valid and decrypts as install/git.sh expects."
