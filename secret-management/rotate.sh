#!/usr/bin/env bash
#
# rotate.sh -- rotate the "main secret".
#
# GPG-encrypts an SSH private key (symmetric / passphrase) and embeds the result
# into an image with steghide, exactly the way install/git.sh expects to extract
# it later:
#
#     steghide extract -sf <image>   ->   dev_key.gpg
#     gpg dev_key.gpg                 ->   dev_key   (the SSH private key)
#
# Usage:
#     ./rotate.sh --ssh-key <path-to-private-key> --target <path-to-image>
#
# You are prompted to paste the passphrase (used for BOTH the gpg and steghide
# layers). It is never written to disk, argv, or shell history. The target image
# is only overwritten AFTER the freshly embedded secret is verified to round-trip.
#
set -euo pipefail

SM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SM_DIR/lib.sh"

usage() {
  cat >&2 <<EOF
Rotate the main secret: GPG-encrypt an SSH private key and steghide-embed it
into an image (matching what install/git.sh extracts).

Usage:
  ${0##*/} --ssh-key <path-to-private-key> --target <path-to-image>

Options:
  --ssh-key <path>   Unprotected OpenSSH private key to embed (-> ~/.ssh/dev_key).
  --target  <path>   JPEG image to embed into; overwritten in place on success.
  -h, --help         Show this help.
EOF
}

SSH_KEY=""; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ssh-key) SSH_KEY="${2:-}"; shift 2 || sm_die "--ssh-key needs a value" ;;
    --target)  TARGET="${2:-}";  shift 2 || sm_die "--target needs a value" ;;
    -h|--help) usage; exit 0 ;;
    *) usage; sm_die "unknown argument: $1" ;;
  esac
done

[ -n "$SSH_KEY" ] || { usage; sm_die "--ssh-key is required"; }
[ -n "$TARGET"  ] || { usage; sm_die "--target is required"; }

sm_require_cmd gpg steghide ssh-keygen mktemp
command -v python3 >/dev/null 2>&1 || sm_info "note: python3 not found; steghide will prompt interactively."

[ -f "$SSH_KEY" ] || sm_die "ssh key not found: $SSH_KEY"
[ -r "$SSH_KEY" ] || sm_die "ssh key not readable: $SSH_KEY"
[ -f "$TARGET"  ] || sm_die "target image not found: $TARGET"
[ -w "$TARGET"  ] || sm_die "target image not writable: $TARGET"

case "${TARGET,,}" in
  *.jpg|*.jpeg) : ;;
  *) sm_info "warning: install/git.sh extracts from a .jpg, but '$TARGET' is not .jpg." ;;
esac

sm_make_workdir
key="$SM_WORKDIR/dev_key"          # plaintext key (embedded name must be dev_key)
gpgf="$SM_WORKDIR/dev_key.gpg"     # encrypted blob (embedded name must be dev_key.gpg)
stego="$SM_WORKDIR/stego.img"      # candidate output, only promoted after verify
vdir="$SM_WORKDIR/verify"

# Copy the key in with strict perms and confirm it is a usable, *unprotected* key
# (install/git.sh loads it with ssh-add and no passphrase).
cp -- "$SSH_KEY" "$key"; chmod 600 "$key"
sm_key_pub "$key" >/dev/null \
  || sm_die "'$SSH_KEY' is not a valid, unprotected OpenSSH private key."
fingerprint="$(sm_key_fingerprint "$key")"
origmode="$(stat -c '%a' "$TARGET" 2>/dev/null || echo 644)"

sm_info "Key to embed : $SSH_KEY"
sm_info "Fingerprint  : $fingerprint"
sm_info "Target image : $TARGET"
sm_info ""

sm_read_passphrase_confirm
pass="$SM_PASSPHRASE"

sm_info "[1/4] Encrypting key (gpg -c, AES256)..."
sm_gpg_encrypt "$key" "$gpgf" "$pass" || sm_die "gpg encryption failed."

sm_info "[2/4] Embedding into image (steghide)..."
if ! sm_steghide_embed "$TARGET" "$gpgf" "$stego" "$pass"; then
  sm_die "steghide embed failed. Is the image big enough to hold $(wc -c <"$gpgf") bytes? Try a larger image."
fi

sm_info "[3/4] Verifying the new image round-trips..."
mkdir -p "$vdir"
sm_steghide_extract "$stego" "$vdir" "$pass" \
  || sm_die "verification failed: could not re-extract from the new image."
[ -f "$vdir/dev_key.gpg" ] \
  || sm_die "verification failed: embedded file is not named 'dev_key.gpg' (install/git.sh would break)."
sm_gpg_decrypt "$vdir/dev_key.gpg" "$vdir/dev_key" "$pass" \
  || sm_die "verification failed: gpg could not decrypt the embedded secret."
cmp -s "$key" "$vdir/dev_key" \
  || sm_die "verification failed: recovered key does not match the input key."

sm_info "[4/4] Promoting verified image over target..."
chmod "$origmode" "$stego" 2>/dev/null || true
mv -f "$stego" "$TARGET"

sm_info ""
sm_info "SUCCESS: secret rotated into $TARGET"
sm_info "  fingerprint: $fingerprint"
sm_info ""
sm_info "Next steps:"
sm_info "  1) Independent check:"
sm_info "       $SM_DIR/validate.sh --target \"$TARGET\" --ssh-key \"$SSH_KEY\""
sm_info "  2) Publish (your single-commit wallpapers flow), e.g.:"
sm_info "       git -C <wallpapers> commit -a --amend --no-edit && git -C <wallpapers> push --force-with-lease"
sm_info "  3) Add the NEW public key to GitLab, confirm access, THEN revoke the OLD key."
sm_info ""
sm_info "Bootstrap filename to remember: '$(basename "${TARGET%.*}")'"
