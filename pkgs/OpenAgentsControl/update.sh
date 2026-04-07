#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

META=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  https://api.github.com/repos/darrenhinde/OpenAgentsControl/releases/latest)
VERSION=$(jq -r '.tag_name' <<< "$META")
CURRENT=$(jq -r '.version' sources.json)
PLATFORM=x86_64-linux

[[ "$VERSION" == "$CURRENT" ]] && { echo "Already up to date ($VERSION)"; exit 0; } || echo "Updating to $VERSION"

url="https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/refs/tags/${VERSION}/install.sh"

echo "URL: $url"

{ read -r hash; read -r path; } < <(nix-prefetch-url --print-path "$url")

echo "Hash: $hash | Path: $path"

sri=$(nix-hash --type sha256 --to-sri "$hash")

echo "SRI: $sri"
echo "Updating sources.json"

jq -n --arg v "$VERSION" --arg url "$url" --arg hash "$sri" \
  '{version: $v, source: $url, hash: $hash}' > sources.json