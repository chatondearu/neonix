#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils gnused nix-prefetch-github
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
CURRENT_NODE_MODULES_HASH=$(jq -r '.node_modules_hash // empty' sources.json 2>/dev/null || echo "")

if [[
  "$VERSION" == "$CURRENT" \
  && -n "$CURRENT_HASH" \
  && "$CURRENT_HASH" != "null" \
  && -n "$CURRENT_NODE_MODULES_HASH" \
  && "$CURRENT_NODE_MODULES_HASH" != "null"
]]; then
  echo "Already up to date ($VERSION)"
  exit 0
fi

echo "Updating to $VERSION"

PREFETCH_JSON=$(nix-prefetch-github anomalyco opencode --rev "v$VERSION" --json)
HASH=$(jq -r '.hash' <<< "$PREFETCH_JSON")

echo "Hash: $HASH"
echo "Computing node_modules hash (fixed-output derivation)"

BUILD_LOG=$(
  nix build --impure --no-link --expr "
    let
      pkgs = import <nixpkgs> {};
      pkg = pkgs.callPackage $(pwd)/default.nix {};
    in
      pkg.passthru.node_modules.overrideAttrs (old: { outputHash = pkgs.lib.fakeHash; })
  " 2>&1 >/dev/null || true
)

NODE_MODULES_HASH=$(sed -n 's/^[[:space:]]*got:[[:space:]]*//p' <<< "$BUILD_LOG" | head -n1)

if [[ -z "$NODE_MODULES_HASH" ]]; then
  echo "Failed to compute node_modules hash."
  echo "$BUILD_LOG" >&2
  exit 1
fi

echo "node_modules hash: $NODE_MODULES_HASH"
echo "Updating sources.json"

jq -n --arg v "$VERSION" --arg hash "$HASH" --arg nmHash "$NODE_MODULES_HASH" \
  '{version: $v, hash: $hash, node_modules_hash: $nmHash}' > sources.json

