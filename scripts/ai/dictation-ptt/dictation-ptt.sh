#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt"
STATE_FILE="$STATE_DIR/state"
PID_FILE="$STATE_DIR/record.pid"
WAV_FILE="$STATE_DIR/capture.wav"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TRANSCRIBE="${DICTATION_TRANSCRIBE:-$SCRIPT_DIR/wyoming_transcribe.py}"
OPENAI_TRANSCRIBE="${DICTATION_OPENAI_TRANSCRIBE:-$SCRIPT_DIR/openai_transcribe.py}"
WHISPER_CPP_TRANSCRIBE="${DICTATION_WHISPER_CPP_TRANSCRIBE:-$SCRIPT_DIR/whisper_cpp_transcribe.py}"
WYOMING_URI="${DICTATION_WYOMING_URI:-tcp://127.0.0.1:10300}"
PARAKEET_URL="${DICTATION_PARAKEET_URL:-http://127.0.0.1:10310/v1}"
WHISPER_URL="${DICTATION_WHISPER_URL:-http://127.0.0.1:10311}"
STT_MODE="${DICTATION_STT:-auto}"
STT_TIMEOUT="${DICTATION_STT_TIMEOUT:-60}"
NOTIFY_TITLE="Dictation"
NOTIFY_ID=991031

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

set_state() {
  ensure_state_dir
  printf '%s\n' "$1" >"$STATE_FILE"
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    tr -d '\n' <"$STATE_FILE"
  else
    printf 'idle'
  fi
}

notify_info() {
  local body="$1"
  echo "$NOTIFY_TITLE: $body" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -r "$NOTIFY_ID" -u low -a Dictation "$NOTIFY_TITLE" "$body" || true
  fi
}

notify_err() {
  local body="$1"
  echo "$NOTIFY_TITLE: $body" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -r "$NOTIFY_ID" -u critical -a Dictation "$NOTIFY_TITLE" "$body" || true
  fi
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
  stop_recording_process
  rm -f "$WAV_FILE"

  if ! command -v pw-record >/dev/null 2>&1; then
    set_state idle
    notify_err "pw-record introuvable (PipeWire)."
    exit 1
  fi

  pw-record --rate=16000 --channels=1 --format=s16 --container=wav "$WAV_FILE" &
  echo $! >"$PID_FILE"

  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    rm -f "$PID_FILE"
    set_state idle
    notify_err "Échec démarrage micro / PipeWire."
    exit 1
  fi

  set_state listening
  notify_info "Écoute…"
}

cmd_stop() {
  ensure_state_dir

  if [[ ! -f "$PID_FILE" ]]; then
    set_state idle
    exit 0
  fi

  stop_recording_process

  if [[ ! -f "$WAV_FILE" ]] || [[ ! -s "$WAV_FILE" ]]; then
    set_state idle
    notify_err "Enregistrement vide ou manquant."
    exit 1
  fi

  if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wtype >/dev/null 2>&1; then
    set_state idle
    notify_err "wl-copy ou wtype manquant."
    exit 1
  fi

  set_state transcribing
  notify_info "Transcription…"

  backend_up() {
    local url="$1"
    curl -fsS -m 0.3 "${url%/v1}/health" >/dev/null 2>&1 \
      || curl -fsS -m 0.3 "$url/models" >/dev/null 2>&1
  }

  run_openai() {
    local base="$1"
    python3 "$OPENAI_TRANSCRIBE" --base-url "$base" --language fr --timeout "$STT_TIMEOUT" "$WAV_FILE"
  }

  run_wyoming() {
    python3 "$TRANSCRIBE" --uri "$WYOMING_URI" --language fr "$WAV_FILE"
  }

  run_whisper() {
    python3 "$WHISPER_CPP_TRANSCRIBE" --base-url "$WHISPER_URL" --language fr --timeout "$STT_TIMEOUT" "$WAV_FILE"
  }

  transcribe_routed() {
    case "$STT_MODE" in
      parakeet) run_openai "$PARAKEET_URL" ;;
      whisper) run_whisper ;;
      wyoming) run_wyoming ;;
      auto)
        if backend_up "$PARAKEET_URL"; then run_openai "$PARAKEET_URL"
        elif backend_up "$WHISPER_URL"; then run_whisper
        else run_wyoming
        fi
        ;;
      *) notify_err "DICTATION_STT invalide: $STT_MODE"; return 1 ;;
    esac
  }

  local text rc
  set +e
  text="$(transcribe_routed 2>/tmp/dictation-ptt-transcribe.err)"
  rc=$?
  set -e

  if [[ "$rc" -eq 2 ]]; then
    set_state idle
    exit 0
  fi

  if [[ "$rc" -ne 0 ]]; then
    local err
    err="$(cat /tmp/dictation-ptt-transcribe.err 2>/dev/null || echo "erreur inconnue")"
    set_state idle
    notify_err "STT / modèle: $err"
    exit 1
  fi

  printf '%s' "$text" | wl-copy
  sleep 0.05
  wtype -M ctrl v -m ctrl
  set_state idle
}

cmd_status() {
  get_state
  echo
}

cmd_toggle() {
  case "$(get_state)" in
    listening) cmd_stop ;;
    transcribing)
      echo "Dictation: transcription en cours" >&2
      exit 1
      ;;
    *) cmd_start ;;
  esac
}

usage() {
  echo "Usage: dictation-ptt start|stop|toggle|status" >&2
  exit 2
}

main() {
  case "${1:-}" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    toggle) cmd_toggle ;;
    status) cmd_status ;;
    *) usage ;;
  esac
}

main "$@"
