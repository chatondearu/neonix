#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix prefetch-npm-deps
# shellcheck shell=bash
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

META=$(curl -fsSL https://registry.npmjs.org/gitnexus/latest)
VERSION=$(jq -r '.version' <<< "$META")
TARBALL_URL=$(jq -r '.dist.tarball' <<< "$META")

CURRENT=$(jq -r '.version' sources.json 2>/dev/null || echo "")
CURRENT_HASH=$(jq -r '.hash // empty' sources.json 2>/dev/null || echo "")
CURRENT_NPM_DEPS_HASH=$(jq -r '.npmDepsHash // empty' sources.json 2>/dev/null || echo "")

LOCK_URL="https://raw.githubusercontent.com/abhigyanpatwari/GitNexus/v${VERSION}/gitnexus/package-lock.json"

if [[
  "$VERSION" == "$CURRENT" \
  && -n "$CURRENT_HASH" \
  && "$CURRENT_HASH" != "null" \
  && -n "$CURRENT_NPM_DEPS_HASH" \
  && "$CURRENT_NPM_DEPS_HASH" != "null"
]]; then
  echo "Already up to date ($VERSION)"
  exit 0
fi

echo "Updating to $VERSION"
echo "Tarball: $TARBALL_URL"
echo "Lockfile: $LOCK_URL"

{ read -r hash; read -r _path; } < <(nix-prefetch-url --print-path "$TARBALL_URL")
TARBALL_HASH=$(nix-hash --type sha256 --to-sri "$hash")

echo "Tarball hash: $TARBALL_HASH"

curl -fsSL "$LOCK_URL" -o package-lock.json

NPM_DEPS_HASH=$(prefetch-npm-deps package-lock.json)
echo "npmDeps hash: $NPM_DEPS_HASH"

jq -n \
  --arg v "$VERSION" \
  --arg tarballHash "$TARBALL_HASH" \
  --arg npmDepsHash "$NPM_DEPS_HASH" \
  '{version: $v, hash: $tarballHash, npmDepsHash: $npmDepsHash}' > sources.json
