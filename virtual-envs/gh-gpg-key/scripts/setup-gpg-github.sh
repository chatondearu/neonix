#!/bin/sh
# Generate a GPG signing key and upload the public part to GitHub via `gh gpg-key add`.
# Requires: gpg, gh; GitHub CLI must be logged in (`gh auth login`) with a token that can manage GPG keys.
#
# Optional env:
#   GPG_REAL_NAME   (default: git user.name or "Git signing")
#   GPG_EMAIL       (default: git user.email — use GitHub noreply if you want private email on commits)
#   GPG_KEY_TITLE   (default: hostname + date)
#   NO_GH_ADD=1     only generate key and print instructions (no API call)
set -e

GPG_EMAIL="${GPG_EMAIL:-$(git config user.email 2>/dev/null)}"
GPG_REAL_NAME="${GPG_REAL_NAME:-$(git config user.name 2>/dev/null)}"
GPG_REAL_NAME="${GPG_REAL_NAME:-Git signing}"
GPG_KEY_TITLE="${GPG_KEY_TITLE:-$(hostname) $(date +%Y-%m-%d)}"

if [ -z "$GPG_EMAIL" ]; then
  echo "Set GPG_EMAIL or git config user.email." >&2
  exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "Need gpg in PATH." >&2
  exit 1
fi

if [ "${NO_GH_ADD:-}" != "1" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "Need gh in PATH (or set NO_GH_ADD=1 to only generate the key)." >&2
    exit 1
  fi
fi

if [ "${NO_GH_ADD:-}" != "1" ] && ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not authenticated. Run: gh auth login -h github.com" >&2
  exit 1
fi

BATCH="$(mktemp)"
trap 'rm -f "$BATCH"' EXIT

# Ed25519 primary key for signing (supported by GitHub for commit verification).
cat > "$BATCH" <<EOF
%no-protection
Key-Type: EDDSA
Key-Curve: Ed25519
Key-Usage: sign
Name-Real: ${GPG_REAL_NAME}
Name-Email: ${GPG_EMAIL}
Expire-Date: 2y
%commit
%echo done
EOF

echo "Generating GPG key for ${GPG_REAL_NAME} <${GPG_EMAIL}>..." >&2
gpg --batch --generate-key "$BATCH"

FPR="$(gpg --list-secret-keys --with-colons --fingerprint "$GPG_EMAIL" 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }')"
if [ -z "$FPR" ]; then
  echo "Could not read new key fingerprint." >&2
  exit 1
fi

ASC="$(mktemp)"
trap 'rm -f "$BATCH" "$ASC"' EXIT
gpg --armor --export "$FPR" > "$ASC"

echo "" >&2
echo "Public key fingerprint: $FPR" >&2
echo "Configure git signing:" >&2
echo "  git config --global user.signingkey $FPR" >&2
echo "  git config --global commit.gpgsign true" >&2
echo "" >&2

if [ "${NO_GH_ADD:-}" = "1" ]; then
  echo "NO_GH_ADD=1 set; public key saved at $ASC (not uploaded)." >&2
  exit 0
fi

gh gpg-key add "$ASC" --title "$GPG_KEY_TITLE"
echo "Uploaded to GitHub as: $GPG_KEY_TITLE" >&2
