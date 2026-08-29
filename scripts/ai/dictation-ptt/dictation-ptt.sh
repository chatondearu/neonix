#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt"
# WAV lives under /tmp (not the small XDG_RUNTIME_DIR tmpfs) so long
# toggle sessions cannot fill the session runtime and orphan pw-record.
DATA_DIR="${DICTATION_DATA_DIR:-${TMPDIR:-/tmp}/dictation-ptt-${UID:-$(id -u)}}"
CONFIG_FILE="${DICTATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt/config.json}"
LOCK_FILE=""
WATCH_PID_FILE=""
TRANSCRIBE_PID_FILE=""
STATE_FILE="$STATE_DIR/state"
PID_FILE="$STATE_DIR/record.pid"
ERR_FILE="$STATE_DIR/transcribe.err"
WAV_FILE="$DATA_DIR/capture.wav"
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
  mkdir -p "$STATE_DIR" "$DATA_DIR"
}

load_config() {
  CFG_MODE=hold
  CFG_KEYBOARD_KEY=ScrollLock
  CFG_SILENCE_ENABLED=true
  CFG_SILENCE_MS=2500
  CFG_MAX_ENABLED=true
  CFG_MAX_SEC=180
  [[ -f "$CONFIG_FILE" ]] || return 0
  if command -v jq >/dev/null 2>&1; then
    CFG_MODE="$(jq -r '.mode // "hold"' "$CONFIG_FILE")"
    CFG_KEYBOARD_KEY="$(jq -r '.keyboard_key // "ScrollLock"' "$CONFIG_FILE")"
    CFG_SILENCE_ENABLED="$(jq -r '.silence_enabled // true' "$CONFIG_FILE")"
    CFG_SILENCE_MS="$(jq -r '.silence_ms // 2500' "$CONFIG_FILE")"
    CFG_MAX_ENABLED="$(jq -r '.max_duration_enabled // true' "$CONFIG_FILE")"
    CFG_MAX_SEC="$(jq -r '.max_sec // 180' "$CONFIG_FILE")"
  fi
}

with_lock() {
  ensure_state_dir
  LOCK_FILE="$STATE_DIR/lock"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    notify_err "Dictation déjà en cours (lock)."
    exit 1
  fi
  "$@"
}

stop_watchers() {
  :
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

stop_pid() {
  local pid="$1"
  [[ -n "$pid" ]] || return 0
  if kill -0 "$pid" 2>/dev/null; then
    kill -INT "$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
    wait_for_process_exit "$pid"
    kill -KILL "$pid" 2>/dev/null || true
  fi
}

# Stop recorders tracked by PID file and any orphan pw-record on our WAV path.
stop_recording_process() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(tr -d '[:space:]' <"$PID_FILE" || true)"
    stop_pid "$pid"
    rm -f "$PID_FILE"
  fi

  local p cmd
  for p in $(pgrep -x pw-record 2>/dev/null || true); do
    cmd="$(tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null || true)"
    if [[ "$cmd" == *"$WAV_FILE"* ]]; then
      stop_pid "$p"
    fi
  done
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

  # Fail fast if the WAV filesystem is full (common when WAV lived on tmpfs).
  local avail_kb
  avail_kb="$(df -Pk "$DATA_DIR" | awk 'NR==2 {print $4}')"
  if [[ -z "${avail_kb:-}" || "$avail_kb" -lt 10240 ]]; then
    set_state idle
    notify_err "Espace disque insuffisant pour l’enregistrement."
    exit 1
  fi

  pw-record --rate=16000 --channels=1 --format=s16 --container=wav "$WAV_FILE" 9>&- &
  local rec_pid=$!
  disown "$rec_pid" 2>/dev/null || true
  printf '%s\n' "$rec_pid" >"$PID_FILE"

  if ! kill -0 "$rec_pid" 2>/dev/null; then
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

  run_tracked() {
    local pid rc
    "$@" 9>&- &
    pid=$!
    echo "$pid" >"$TRANSCRIBE_PID_FILE"
    wait "$pid"
    rc=$?
    rm -f "$TRANSCRIBE_PID_FILE"
    return "$rc"
  }

  run_openai() {
    local base="$1"
    run_tracked python3 "$OPENAI_TRANSCRIBE" --base-url "$base" --language fr --timeout "$STT_TIMEOUT" "$WAV_FILE"
  }

  run_wyoming() {
    run_tracked python3 "$TRANSCRIBE" --uri "$WYOMING_URI" --language fr "$WAV_FILE"
  }

  run_whisper() {
    run_tracked python3 "$WHISPER_CPP_TRANSCRIBE" --base-url "$WHISPER_URL" --language fr --timeout "$STT_TIMEOUT" "$WAV_FILE"
  }

  transcribe_routed() {
    case "$STT_MODE" in
      parakeet) run_openai "$PARAKEET_URL" ;;
      whisper) run_whisper ;;
      wyoming) run_wyoming ;;
      auto)
        # Try each healthy backend in order; on hard failure continue (e.g. Parakeet
        # rejects audio longer than the single-pass limit without -long-audio).
        # Exit 2 = empty transcript: stop without trying another backend.
        local errf out rc
        errf="$(mktemp)"
        try_backend() {
          out="$("$@" 2>"$errf")"
          rc=$?
          if [[ "$rc" -eq 0 ]]; then
            printf '%s' "$out"
            rm -f "$errf"
            return 0
          fi
          if [[ "$rc" -eq 2 ]]; then
            cat "$errf" >&2
            rm -f "$errf"
            return 2
          fi
          cat "$errf" >&2
          return 1
        }
        if backend_up "$PARAKEET_URL"; then
          try_backend run_openai "$PARAKEET_URL" && return 0
          [[ $? -eq 2 ]] && return 2
        fi
        if backend_up "$WHISPER_URL"; then
          try_backend run_whisper && return 0
          [[ $? -eq 2 ]] && return 2
        fi
        try_backend run_wyoming
        rc=$?
        rm -f "$errf"
        return "$rc"
        ;;
      *) notify_err "DICTATION_STT invalide: $STT_MODE"; return 1 ;;
    esac
  }

  local text rc
  set +e
  text="$(transcribe_routed 2>"$ERR_FILE")"
  rc=$?
  set -e

  if [[ "$rc" -eq 2 ]]; then
    set_state idle
    exit 0
  fi

  if [[ "$rc" -ne 0 ]]; then
    local err
    err="$(cat "$ERR_FILE" 2>/dev/null || echo "erreur inconnue")"
    set_state idle
    notify_err "STT / modèle: $err"
    exit 1
  fi

  printf '%s' "$text" | wl-copy
  sleep 0.05
  # Ctrl+Shift+V: works in terminals (Ghostty) and most GUI apps
  wtype -M ctrl -M shift v -m shift -m ctrl
  set_state idle
}

cmd_status() {
  get_state
  echo
}

cmd_toggle() {
  case "$(get_state)" in
    listening) cmd_stop ;;
    transcribing) exit 0 ;;
    *) cmd_start ;;
  esac
}

cmd_force_stop() {
  ensure_state_dir
  stop_watchers
  stop_recording_process
  if [[ -f "$TRANSCRIBE_PID_FILE" ]]; then
    stop_pid "$(tr -d '[:space:]' <"$TRANSCRIBE_PID_FILE")"
    rm -f "$TRANSCRIBE_PID_FILE"
  fi
  local p
  for p in $(pgrep -f 'whisper_cpp_transcribe|openai_transcribe|wyoming_transcribe' 2>/dev/null || true); do
    stop_pid "$p"
  done
  set_state idle
  notify_info "Arrêt forcé."
}

cmd_cancel() {
  cmd_force_stop
}

cmd_clean() {
  ensure_state_dir
  rm -f "$WAV_FILE" "$DATA_DIR"/*.wav 2>/dev/null || true
  rm -f "$PID_FILE" "$TRANSCRIBE_PID_FILE"
  notify_info "Cache audio nettoyé."
}

cmd_reset() {
  cmd_force_stop
  cmd_clean
  set_state idle
}

usage() {
  echo "Usage: dictation-ptt start|stop|toggle|status|force-stop|cancel|clean|reset" >&2
  exit 2
}

main() {
  load_config
  WATCH_PID_FILE="$STATE_DIR/watch.pid"
  TRANSCRIBE_PID_FILE="$STATE_DIR/transcribe.pid"
  case "${1:-}" in
    start) with_lock cmd_start ;;
    stop) with_lock cmd_stop ;;
    toggle) with_lock cmd_toggle ;;
    status) cmd_status "${2:-}" ;;
    force-stop) with_lock cmd_force_stop ;;
    cancel) with_lock cmd_cancel ;;
    clean) with_lock cmd_clean ;;
    reset) with_lock cmd_reset ;;
    *) usage ;;
  esac
}

main "$@"
