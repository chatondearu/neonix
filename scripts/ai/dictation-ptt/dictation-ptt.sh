#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt"
PID_FILE="$STATE_DIR/record.pid"
WAV_FILE="$STATE_DIR/capture.wav"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TRANSCRIBE="${DICTATION_TRANSCRIBE:-$SCRIPT_DIR/wyoming_transcribe.py}"
WYOMING_URI="${DICTATION_WYOMING_URI:-tcp://127.0.0.1:10300}"
NOTIFY_TITLE="Dictation"

notify_err() {
  local body="$1"
  echo "$NOTIFY_TITLE: $body" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical -a Dictation "$NOTIFY_TITLE" "$body" || true
  fi
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

wait_for_process_exit() {
  local pid="$1"
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    if ((i >= 50)); then
      kill -TERM "$pid" 2>/dev/null || true
      break
    fi
    sleep 0.1
    ((i++)) || true
  done
  wait "$pid" 2>/dev/null || true
}

stop_recording_process() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill -INT "$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
      wait_for_process_exit "$pid"
    fi
    rm -f "$PID_FILE"
  fi
}

cmd_start() {
  ensure_state_dir
  # Restart cleanly if already recording
  stop_recording_process
  rm -f "$WAV_FILE"

  if ! command -v pw-record >/dev/null 2>&1; then
    notify_err "pw-record introuvable (PipeWire)."
    exit 1
  fi

  # 16 kHz mono s16 WAV for Whisper
  pw-record --rate=16000 --channels=1 --format=s16 --container=wav "$WAV_FILE" &
  echo $! >"$PID_FILE"

  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    rm -f "$PID_FILE"
    notify_err "Échec démarrage micro / PipeWire."
    exit 1
  fi
}

cmd_stop() {
  ensure_state_dir

  if [[ ! -f "$PID_FILE" ]]; then
    exit 0
  fi

  stop_recording_process

  if [[ ! -f "$WAV_FILE" ]] || [[ ! -s "$WAV_FILE" ]]; then
    notify_err "Enregistrement vide ou manquant."
    exit 1
  fi

  if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wtype >/dev/null 2>&1; then
    notify_err "wl-copy ou wtype manquant."
    exit 1
  fi

  local text rc
  set +e
  text="$(python3 "$TRANSCRIBE" --uri "$WYOMING_URI" --language fr "$WAV_FILE" 2>/tmp/dictation-ptt-transcribe.err)"
  rc=$?
  set -e

  if [[ "$rc" -eq 2 ]]; then
    # Empty transcript: no paste, no critical noise
    exit 0
  fi

  if [[ "$rc" -ne 0 ]]; then
    local err
    err="$(cat /tmp/dictation-ptt-transcribe.err 2>/dev/null || echo "erreur inconnue")"
    notify_err "STT / modèle: $err"
    exit 1
  fi

  printf '%s' "$text" | wl-copy
  # Small delay so the focused client receives clipboard before paste
  sleep 0.05
  wtype -M ctrl v -m ctrl
}

usage() {
  echo "Usage: dictation-ptt start|stop" >&2
  exit 2
}

main() {
  case "${1:-}" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    *) usage ;;
  esac
}

main "$@"
