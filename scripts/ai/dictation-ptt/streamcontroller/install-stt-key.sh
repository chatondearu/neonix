#!/usr/bin/env bash
# Merge the versioned STT key into the live StreamController page.
# Mode: hold (Key Down/Up start/stop) or toggle (single toggle command).
#
# StreamController keeps the page in memory and can overwrite disk on exit, so
# we stop it (if running), write the fragment, then relaunch.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${DICTATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt/config.json}"
# Nix StreamController uses the Flatpak-style data path on this machine.
DEFAULT_PAGE_DIR="${HOME}/.var/app/com.core447.StreamController/data/pages"
PAGE_DIR="${STREAMCONTROLLER_PAGES_DIR:-$DEFAULT_PAGE_DIR}"
MODE=""
RESTART_SC=1

usage() {
  echo "Usage: install-stt-key.sh [--mode hold|toggle] [--no-restart]" >&2
  echo "  Default mode from config.json (toggle if missing)." >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || usage
      MODE="$2"
      shift 2
      ;;
    --no-restart)
      RESTART_SC=0
      shift
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
    echo toggle
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -r '.mode // "toggle"' "$CONFIG_FILE"
  else
    grep -oE '"mode"[[:space:]]*:[[:space:]]*"[^"]+"' "$CONFIG_FILE" \
      | head -1 \
      | sed -E 's/.*"([^"]+)"$/\1/' || echo toggle
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

if [[ ! -d "$PAGE_DIR" ]]; then
  PAGE_DIR="$DEFAULT_PAGE_DIR"
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

sc_running() {
  # Linux truncates /proc/comm to 15 chars → "StreamControlle"
  pgrep -x StreamControlle >/dev/null 2>&1 \
    || pgrep -x StreamController >/dev/null 2>&1 \
    || pgrep -f '[S]treamController' >/dev/null 2>&1
}

sc_was_running=0
if sc_running; then
  sc_was_running=1
fi

stop_streamcontroller() {
  pkill -x StreamControlle 2>/dev/null || true
  pkill -x StreamController 2>/dev/null || true
  pkill -f '[S]treamController' 2>/dev/null || true
  local i
  for i in $(seq 1 30); do
    sc_running || return 0
    sleep 0.1
  done
  pkill -9 -x StreamControlle 2>/dev/null || true
  pkill -9 -f '[S]treamController' 2>/dev/null || true
}

start_streamcontroller() {
  local bin=""
  if command -v streamcontroller >/dev/null 2>&1; then
    bin=$(command -v streamcontroller)
  elif command -v StreamController >/dev/null 2>&1; then
    bin=$(command -v StreamController)
  fi
  if [[ -z "$bin" ]]; then
    echo "StreamController binary not on PATH; page updated but app not relaunched." >&2
    return 0
  fi
  # -b matches ~/.config/autostart/StreamController.desktop
  nohup "$bin" -b >/dev/null 2>&1 &
  disown || true
}

if [[ "$RESTART_SC" -eq 1 && "$sc_was_running" -eq 1 ]]; then
  stop_streamcontroller
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

if [[ "$RESTART_SC" -eq 1 ]]; then
  if [[ "$sc_was_running" -eq 1 ]]; then
    start_streamcontroller
    echo "StreamController relaunched to load ${MODE} fragment."
  else
    echo "StreamController was not running; start it to use the ${MODE} key."
  fi
else
  echo "Restart StreamController to reload the page (--no-restart)."
fi
