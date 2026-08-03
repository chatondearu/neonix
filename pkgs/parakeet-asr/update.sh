#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

META=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/achetronic/parakeet/releases/latest)

VERSION=$(jq -r '.tag_name' <<< "$META" | sed 's/^v//')
CURRENT=$(jq -r '.version' sources.json 2>/dev/null || echo "")
CURRENT_HASH=$(jq -r '.hash // empty' sources.json 2>/dev/null || echo "")

ASSET=$(jq -r '.assets[] | select(.name|test("linux.*amd64|Linux_x86_64")) | .browser_download_url' <<<"$META" | head -n1)

if [[
  "$VERSION" == "$CURRENT" \
  && -n "$CURRENT_HASH" \
  && "$CURRENT_HASH" != "null"
]]; then
  echo "Already up to date ($VERSION)"
  exit 0
fi

echo "Updating to $VERSION"
echo "URL: $ASSET"

{ read -r hash; read -r _path; } < <(nix-prefetch-url --print-path "$ASSET")
SRI=$(nix-hash --type sha256 --to-sri "$hash")

echo "Hash: $SRI"

jq -n --arg v "$VERSION" --arg url "$ASSET" --arg hash "$SRI" \
  '{version: $v, url: $url, hash: $hash}' > sources.json
