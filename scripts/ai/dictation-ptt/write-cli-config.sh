#!/usr/bin/env bash
# Write ~/.config/dictation-ptt/config.json from DMS settings args, then sync niri binds.
set -euo pipefail

MODE="${1:-hold}"
KEYBOARD_KEY="${2:-ScrollLock}"
SILENCE_ENABLED="${3:-true}"
SILENCE_MS="${4:-2500}"
MAX_DURATION_ENABLED="${5:-true}"
MAX_SEC="${6:-180}"
KEYBOARD_DAEMON="${7:-true}"

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt"
CFG_FILE="${DICTATION_CONFIG:-$CFG_DIR/config.json}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$(dirname "$CFG_FILE")"

to_bool_json() {
  case "${1,,}" in
    true|1|yes|on) echo true ;;
    *) echo false ;;
  esac
}

SILENCE_JSON="$(to_bool_json "$SILENCE_ENABLED")"
MAX_JSON="$(to_bool_json "$MAX_DURATION_ENABLED")"
DAEMON_JSON="$(to_bool_json "$KEYBOARD_DAEMON")"

if command -v jq >/dev/null 2>&1; then
  jq -nc \
    --arg mode "$MODE" \
    --arg keyboard_key "$KEYBOARD_KEY" \
    --argjson silence_enabled "$SILENCE_JSON" \
    --argjson silence_ms "$SILENCE_MS" \
    --argjson max_duration_enabled "$MAX_JSON" \
    --argjson max_sec "$MAX_SEC" \
    --argjson keyboard_daemon "$DAEMON_JSON" \
    '{
      mode: $mode,
      keyboard_key: $keyboard_key,
      silence_enabled: $silence_enabled,
      silence_ms: $silence_ms,
      max_duration_enabled: $max_duration_enabled,
      max_sec: $max_sec,
      keyboard_daemon: $keyboard_daemon
    }' >"$CFG_FILE"
else
  printf '%s\n' \
    "{\"mode\":\"${MODE}\",\"keyboard_key\":\"${KEYBOARD_KEY}\",\"silence_enabled\":${SILENCE_JSON},\"silence_ms\":${SILENCE_MS},\"max_duration_enabled\":${MAX_JSON},\"max_sec\":${MAX_SEC},\"keyboard_daemon\":${DAEMON_JSON}}" \
    >"$CFG_FILE"
fi

# niri fallback binds (disabled/minimal when evdev daemon is on)
if [[ -f "$SCRIPT_DIR/sync-niri-bind.sh" ]]; then
  bash "$SCRIPT_DIR/sync-niri-bind.sh" || true
fi

# Keep Stream Deck fragment aligned with mode (restart StreamController to apply)
if [[ -f "$SCRIPT_DIR/streamcontroller/install-stt-key.sh" ]]; then
  bash "$SCRIPT_DIR/streamcontroller/install-stt-key.sh" --mode "$MODE" || true
fi

# Reload keyboard daemon so it picks up mode/key immediately
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user try-restart dictation-ptt-keys.service 2>/dev/null || true
fi
