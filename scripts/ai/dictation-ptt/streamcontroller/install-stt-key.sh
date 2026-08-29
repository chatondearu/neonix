#!/usr/bin/env bash
# Merge the versioned STT key into the live StreamController page.
# Mode: hold (Key Down/Up start/stop) or toggle (single toggle command).
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${DICTATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt/config.json}"
PAGE_DIR="${STREAMCONTROLLER_PAGES_DIR:-${XDG_DATA_HOME:-$HOME/.var/app/com.core447.StreamController/data}/pages}"
MODE=""

usage() {
  echo "Usage: install-stt-key.sh [--mode hold|toggle]" >&2
  echo "  Default mode from \$DICTATION_CONFIG or ~/.config/dictation-ptt/config.json (hold if missing)." >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || usage
      MODE="$2"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

read_mode_from_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo hold
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -r '.mode // "hold"' "$CONFIG_FILE"
  else
    grep -oE '"mode"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG_FILE" \
      | head -1 \
      | sed -E 's/.*"([^"]+)"$/\1/' || echo hold
  fi
}

if [[ -z "$MODE" ]]; then
  MODE="$(read_mode_from_config)"
fi

case "$MODE" in
  hold) FRAGMENT="${SCRIPT_DIR}/stt-key.json" ;;
  toggle) FRAGMENT="${SCRIPT_DIR}/stt-key-toggle.json" ;;
  *)
    echo "Invalid mode: $MODE (expected hold or toggle)" >&2
    exit 1
    ;;
esac

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

echo "Installed STT key (${MODE}) at ${COORDS} → ${PAGE}"
echo "Backup: ${backup}"
echo "Restart StreamController to reload the page."
