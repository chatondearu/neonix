#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

BUILD=$(jq -r '.build' sources.json)
LATEST_TAG=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  https://api.github.com/repos/ggml-org/llama.cpp/releases/latest \
  | jq -r '.tag_name' | sed 's/^b//')

CURRENT_PREBUILT=$(jq -r '.prebuilt.version // empty' sources.json)
CURRENT_HASH=$(jq -r '.prebuilt.hash // empty' sources.json)

ASSET="llama-b${LATEST_TAG}-bin-ubuntu-x64.tar.gz"
ASSET_URL="https://github.com/ggml-org/llama.cpp/releases/download/b${LATEST_TAG}/${ASSET}"

echo "Build mode: $BUILD"
echo "Latest upstream tag: b${LATEST_TAG}"
echo "Note: official Linux CPU binaries have no CUDA; keep build=nixpkgs-cuda for GPU llama-server."

if [[ "$LATEST_TAG" == "$CURRENT_PREBUILT" && -n "$CURRENT_HASH" && "$CURRENT_HASH" != "null" ]]; then
  echo "Prebuilt metadata already up to date (b${LATEST_TAG})"
  exit 0
fi

echo "Updating prebuilt metadata to b${LATEST_TAG}"
echo "URL: $ASSET_URL"

{ read -r hash; read -r _path; } < <(nix-prefetch-url --print-path "$ASSET_URL")
SRI=$(nix-hash --type sha256 --to-sri "$hash")

echo "Hash: $SRI"

jq --arg v "$LATEST_TAG" --arg hash "$SRI" \
  '.prebuilt = {version: $v, hash: $hash}' \
  sources.json > sources.json.new
mv sources.json.new sources.json

echo "To switch to CPU-only prebuilt binaries, set build to prebuilt-cpu in sources.json."
