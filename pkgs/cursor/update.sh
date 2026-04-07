#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix _7zz
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

META=$(curl -fsSL "https://api2.cursor.sh/updates/api/download/stable/linux-x64/cursor")
VERSION=$(jq -r '.version' <<< "$META")
CURRENT=$(jq -r '.version' sources.json)
PLATFORM_PAIR=x86_64-linux:linux-x64

[[ "$VERSION" == "$CURRENT" ]] && { echo "Already up to date ($VERSION)"; exit 0; } || echo "Updating to $VERSION"

VSCODE=""

IFS=: read -r sys platform <<< "$PLATFORM_PAIR"
meta=$(curl -fsSL "https://api2.cursor.sh/updates/api/download/stable/$platform/cursor")
version=$(jq -r '.version' <<< "$meta")

[[ "$version" != "$VERSION" ]] && { echo "Version mismatch: $sys has $version, expected $VERSION"; exit 1; }

echo "Version: $version | Platform: $sys"

url=$(jq -r '.downloadUrl' <<< "$meta")

echo "URL: $url"

{ read -r hash; read -r path; } < <(nix-prefetch-url --print-path "$url")

echo "Hash: $hash | Path: $path"

sri=$(nix-hash --type sha256 --to-sri "$hash")

echo "SRI: $sri"

if [[ "$sys" == "x86_64-linux" ]]; then
  echo "Extracting VSCode version from $path"
  VSCODE=$(7zz x -so "$path" "usr/share/cursor/resources/app/product.json" 2>/dev/null | jq -r '.vscodeVersion')
fi

echo "Updating sources.json"

jq -n --arg v "$VERSION" --arg vs "$VSCODE" --arg url "$url" --arg hash "$sri" \
  '{version: $v, vscodeVersion: $vs, source: $url, hash: $hash}' > sources.json