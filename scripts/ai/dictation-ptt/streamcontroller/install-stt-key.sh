#!/usr/bin/env bash
# Merge the versioned STT hold-to-talk key into the live StreamController page.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT="${SCRIPT_DIR}/stt-key.json"
PAGE_DIR="${STREAMCONTROLLER_PAGES_DIR:-${XDG_DATA_HOME:-$HOME/.var/app/com.core447.StreamController/data}/pages}"
# Nix StreamController still uses the Flatpak-style data path by default:
if [[ ! -d "$PAGE_DIR" ]]; then
  PAGE_DIR="$HOME/.var/app/com.core447.StreamController/data/pages"
fi
PAGE="${PAGE_DIR}/default.json"
COORDS="$(jq -r '.coords // "1x0"' "$FRAGMENT")"

if [[ ! -f "$FRAGMENT" ]]; then
  echo "Missing fragment: $FRAGMENT" >&2
  exit 1
fi

if [[ ! -f "$PAGE" ]]; then
  echo "Missing StreamController page: $PAGE" >&2
  echo "Start StreamController once to create it, or copy default-page.snapshot.json there." >&2
  exit 1
fi

backup="${PAGE}.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$PAGE" "$backup"

tmp="$(mktemp)"
jq --arg coords "$COORDS" --slurpfile frag "$FRAGMENT" \
  '.keys[$coords] = $frag[0].key' \
  "$PAGE" >"$tmp"
mv "$tmp" "$PAGE"

echo "Installed STT key at ${COORDS} → ${PAGE}"
echo "Backup: ${backup}"
echo "Restart StreamController to reload the page."
