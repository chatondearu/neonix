#!/usr/bin/env bash
# Run ON the Synology as root (copy or pipe via ssh). Same logic as bootstrap-remote when logged in as root.
set -euo pipefail

stacks_dir="${1:-/volume1/docker/stacks}"

mkdir -p "$stacks_dir"
chmod 755 "$stacks_dir"

if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  echo "Docker already usable."
  exit 0
fi

if ! command -v synopkg >/dev/null; then
  echo "synopkg not found." >&2
  exit 1
fi

for pkg in ContainerManager Docker; do
  if synopkg status "$pkg" 2>/dev/null | grep -q '^Status: \[installed\]'; then
    synopkg start "$pkg" || true
    exit 0
  fi
done

synopkg install ContainerManager
synopkg start ContainerManager
