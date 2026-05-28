#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

META=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  https://api.github.com/repos/anomalyco/opencode/releases/latest)

VERSION=$(jq -r '.tag_name' <<< "$META" | sed 's/^v//')
CURRENT=$(jq -r '.version' sources.json 2>/dev/null || echo "")
CURRENT_HASH=$(jq -r '.hash // empty' sources.json 2>/dev/null || echo "")

ASSET_URL="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/opencode-linux-x64.tar.gz"

if [[
  "$VERSION" == "$CURRENT" \
  && -n "$CURRENT_HASH" \
  && "$CURRENT_HASH" != "null"
]]; then
  echo "Already up to date ($VERSION)"
  exit 0
fi

echo "Updating to $VERSION"
echo "URL: $ASSET_URL"

{ read -r hash; read -r _path; } < <(nix-prefetch-url --print-path "$ASSET_URL")
SRI=$(nix-hash --type sha256 --to-sri "$hash")

echo "Hash: $SRI"

jq -n --arg v "$VERSION" --arg hash "$SRI" \
  '{version: $v, hash: $hash}' > sources.json
