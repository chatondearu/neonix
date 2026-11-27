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
STREAM_PID_FILE=""
STATE_FILE="$STATE_DIR/state"
LISTEN_STARTED_FILE="$STATE_DIR/listening_started"
PID_FILE="$STATE_DIR/record.pid"
ERR_FILE="$STATE_DIR/transcribe.err"
STREAM_OUT_FILE="$STATE_DIR/stream.txt"
STREAM_SNAPSHOT_FILE="$STATE_DIR/stream.snapshot"
STREAM_ERR_FILE="$STATE_DIR/stream.err"
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
STREAM_BIN="${DICTATION_STREAM_BIN:-whisper-stream}"
STREAM_MODEL="${DICTATION_STREAM_MODEL:-/hdd/whisper/ggml-small.bin}"
STREAM_STEP_MS="${DICTATION_STREAM_STEP_MS:-500}"
STREAM_LENGTH_MS="${DICTATION_STREAM_LENGTH_MS:-5000}"
STREAM_KEEP_MS="${DICTATION_STREAM_KEEP_MS:-200}"
NOTIFY_TITLE="Dictation"
NOTIFY_ID=991031

# auto|stream: decode while held via whisper-stream (ADR-006).
# parakeet|whisper|wyoming: legacy batch POST/Wyoming after release.
uses_streaming_stt() {
  case "$STT_MODE" in
    auto | stream) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR" "$DATA_DIR"
}

load_config() {
  CFG_MODE=toggle
  CFG_KEYBOARD_KEY=Pause
  CFG_SILENCE_ENABLED=true
  CFG_SILENCE_MS=2500
  CFG_MAX_ENABLED=true
  CFG_MAX_SEC=180
  [[ -f "$CONFIG_FILE" ]] || return 0
  if command -v jq >/dev/null 2>&1; then
    CFG_MODE="$(jq -r '.mode // "toggle"' "$CONFIG_FILE")"
    CFG_KEYBOARD_KEY="$(jq -r '.keyboard_key // "Pause"' "$CONFIG_FILE")"
    CFG_SILENCE_ENABLED="$(jq -r 'if has("silence_enabled") then (.silence_enabled | tostring) else "true" end' "$CONFIG_FILE")"
    CFG_SILENCE_MS="$(jq -r '.silence_ms // 2500' "$CONFIG_FILE")"
    CFG_MAX_ENABLED="$(jq -r 'if has("max_duration_enabled") then (.max_duration_enabled | tostring) else "true" end' "$CONFIG_FILE")"
    CFG_MAX_SEC="$(jq -r '.max_sec // 180' "$CONFIG_FILE")"
  fi
}

acquire_lock() {
  ensure_state_dir
  LOCK_FILE="$STATE_DIR/lock"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    notify_err "Dictation déjà en cours (lock)."
    exit 1
  fi
}

acquire_lock_wait() {
  local timeout="${1:-2}"
  ensure_state_dir
  LOCK_FILE="$STATE_DIR/lock"
  exec 9>"$LOCK_FILE"
  flock -w "$timeout" 9
}

release_lock() {
  flock -u 9 2>/dev/null || true
  exec 9>&-
}

with_lock() {
  acquire_lock
  "$@"
  release_lock
}

start_watchers() {
  stop_watchers
  local self="${DICTATION_BIN:-dictation-ptt}"
  (
    if [[ "$CFG_MAX_ENABLED" == "true" ]]; then
      sleep "$CFG_MAX_SEC" || exit 0
      "$self" stop || true
    fi
  ) 9>&- &
  local max_pid=$!
  (
    [[ "$CFG_SILENCE_ENABLED" == "true" ]] || exit 0
    bash "$SCRIPT_DIR/silence-watch.sh" "$WAV_FILE" "$CFG_SILENCE_MS" "$self"
  ) 9>&- &
  local sil_pid=$!
  printf '%s %s\n' "$max_pid" "$sil_pid" >"$WATCH_PID_FILE"
}

stop_watchers() {
  [[ -f "$WATCH_PID_FILE" ]] || return 0
  local p
  for p in $(tr -d '\n' <"$WATCH_PID_FILE"); do
    [[ "$p" -eq "$PPID" ]] && continue
    stop_pid "$p"
  done
  rm -f "$WATCH_PID_FILE"
}

set_state() {
  ensure_state_dir
  printf '%s\n' "$1" >"$STATE_FILE"
  if [[ "$1" == "listening" ]]; then
    date +%s%3N >"$LISTEN_STARTED_FILE"
  elif [[ "$1" == "idle" ]]; then
    rm -f "$LISTEN_STARTED_FILE"
  fi
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    tr -d '\n' <"$STATE_FILE"
  else
    printf 'idle'
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
  # shortcut: 5s wait made PTT release feel hung; CUDA whisper-stream often
  # ignores SIGINT. Kill after ~0.3s. Upgrade if a real flush-on-stop lands.
  while kill -0 "$pid" 2>/dev/null; do
    if ((i >= 6)); then
      kill -KILL "$pid" 2>/dev/null || true
      break
    fi
    sleep 0.05
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

stop_stream_process() {
  if [[ -f "$STREAM_PID_FILE" ]]; then
    local pid
    pid="$(tr -d '[:space:]' <"$STREAM_PID_FILE" || true)"
    stop_pid "$pid"
    rm -f "$STREAM_PID_FILE"
  fi
}

# Start whisper-stream so PCM is decoded while the key is held (not after release).
start_stream_session() {
  if ! command -v "$STREAM_BIN" >/dev/null 2>&1; then
    notify_err "whisper-stream introuvable (whisper-cpp)."
    return 1
  fi
  if [[ ! -f "$STREAM_MODEL" ]]; then
    notify_err "Modèle streaming introuvable: $STREAM_MODEL"
    return 1
  fi

  rm -f "$STREAM_OUT_FILE" "$STREAM_ERR_FILE"
  : >"$STREAM_OUT_FILE"

  local -a cmd=(
    "$STREAM_BIN"
    -m "$STREAM_MODEL"
    -l fr
    -f "$STREAM_OUT_FILE"
    --step "$STREAM_STEP_MS"
    --length "$STREAM_LENGTH_MS"
    --keep "$STREAM_KEEP_MS"
    --no-fallback
  )
  if [[ -n "${DICTATION_STREAM_CAPTURE:-}" ]]; then
    cmd+=(-c "$DICTATION_STREAM_CAPTURE")
  fi
  if [[ "${DICTATION_STREAM_NO_GPU:-}" == "1" ]]; then
    cmd+=(-ng)
  fi

  "${cmd[@]}" 9>&- >>"$STREAM_ERR_FILE" 2>&1 &
  local stream_pid=$!
  disown "$stream_pid" 2>/dev/null || true
  printf '%s\n' "$stream_pid" >"$STREAM_PID_FILE"

  if ! kill -0 "$stream_pid" 2>/dev/null; then
    rm -f "$STREAM_PID_FILE"
    notify_err "Échec démarrage whisper-stream."
    return 1
  fi
  return 0
}

finalize_stream_text() {
  local src="$STREAM_OUT_FILE"
  [[ -f "$STREAM_SNAPSHOT_FILE" ]] && src="$STREAM_SNAPSHOT_FILE"
  [[ -f "$src" ]] || return 0
  # Inline awk: Nix flakes omit untracked sibling files from the package src,
  # which left stop stuck in transcribing (awk -f missing + set -e).
  # Same window only on real containment; last rewrite wins (ADR-006).
  # shortcut: no --keep-context; it chained outro hallucinations. Upgrade if
  # a French initial-prompt lands in whisper-stream.
  local prog
  prog=$(cat <<'AWK'
function fold(s, t) {
  t = tolower(s)
  gsub(/’/, "'", t)
  return t
}
function is_filler_tok(w, t) {
  t = fold(w)
  gsub(/[.,;:!?…«»"()\-]/, "", t)
  return (t ~ /^(euh|heu+|hum+|hmm+|hm|uh+|um+|pff|bah)$/)
}
function is_filler_line(s, n, i, w, keep) {
  n = split(s, w, / +/)
  keep = 0
  for (i = 1; i <= n; i++) {
    if (w[i] == "" || w[i] == "..." || w[i] == "…") continue
    if (is_filler_tok(w[i])) continue
    keep = 1
    break
  }
  return (keep == 0)
}
function is_junk(s, t) {
  if (s == "" || s == "..." || s == "…") return 1
  if (s ~ /^\.{2,}$/) return 1
  if (s ~ /^\[[^]]+\]$/) return 1
  if (s ~ /^\*.*\*$/) return 1
  t = fold(s)
  if (t ~ /sous-titres/ || t ~ /amara\.org/) return 1
  if (t ~ /merci d.avoir regard/) return 1
  if (t ~ /cette vid[eé]o/) return 1
  if (t ~ /abonnez-vous/ || t ~ /vous abonner/ || t ~ /abonner . la cha/) return 1
  if (t ~ /dans la description/) return 1
  if (t ~ /like and subscribe/ || t ~ /thanks for watching/) return 1
  if (t ~ /bruit de /) return 1
  if (t ~ /^[a-z0-9.-]+\.(com|org|net|fr)\.?$/) return 1
  if (is_filler_line(s)) return 1
  return 0
}
function norm(s, t) {
  t = fold(s)
  gsub(/n'/, " ", t)
  gsub(/[^a-z0-9 ]/, "", t)
  gsub(/^ne /, "", t)
  gsub(/ ne /, " ", t)
  gsub(/  +/, " ", t)
  sub(/^ +/, "", t)
  sub(/ +$/, "", t)
  return t
}
function is_rev(a, b, na, nb) {
  na = norm(a)
  nb = norm(b)
  if (na == "" || nb == "") return 0
  return (index(nb, na) || index(na, nb))
}
function wordkey(w, t) {
  t = fold(w)
  gsub(/[.,;:!?…«»"()\-]/, "", t)
  return t
}
function scrub(s, n, i, w, prev, out, k) {
  gsub(/\*[^*]*\*/, " ", s)
  n = split(s, w, / +/)
  prev = ""
  out = ""
  for (i = 1; i <= n; i++) {
    if (w[i] == "") continue
    if (is_filler_tok(w[i])) continue
    k = wordkey(w[i])
    if (k != "" && k == prev) continue
    prev = k
    if (out != "") out = out " "
    out = out w[i]
  }
  return out
}
function commit() {
  if (cur == "") return
  if (acc != "") acc = acc " "
  acc = acc cur
  cur = ""
}
NF == 0 { next }
is_junk($0) { next }
cur == "" { cur = $0; next }
is_rev(cur, $0) { cur = $0; next }
{ commit(); cur = $0 }
END {
  commit()
  print scrub(acc)
}
AWK
)
  tr -d '\r' <"$src" \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | awk "$prog" || true
}

worker_pid_alive() {
  local f="$1" pid=""
  [[ -f "$f" ]] || return 1
  pid="$(tr -d '[:space:]' <"$f" || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

cmd_start() {
  ensure_state_dir
  if [[ "$(get_state)" == "transcribing" ]]; then
    if worker_pid_alive "$STREAM_PID_FILE" || worker_pid_alive "$TRANSCRIBE_PID_FILE"; then
      notify_err "Transcription en cours."
      exit 1
    fi
    set_state idle
  fi
  stop_stream_process
  stop_recording_process
  rm -f "$WAV_FILE" "$STREAM_OUT_FILE" "$STREAM_SNAPSHOT_FILE" "$STREAM_ERR_FILE"

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

  if uses_streaming_stt; then
    if ! start_stream_session; then
      stop_recording_process
      set_state idle
      exit 1
    fi
  fi

  set_state listening
  start_watchers
}

stop_prepare_listening() {
  ensure_state_dir

  if [[ "$(get_state)" == "transcribing" ]]; then
    return 2
  fi

  if [[ ! -f "$PID_FILE" ]]; then
    stop_stream_process
    set_state idle
    return 1
  fi

  stop_recording_process

  if ! uses_streaming_stt; then
    if [[ ! -f "$WAV_FILE" ]] || [[ ! -s "$WAV_FILE" ]]; then
      set_state idle
      notify_err "Enregistrement vide ou manquant."
      return 1
    fi
  fi

  if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wtype >/dev/null 2>&1; then
    stop_stream_process
    set_state idle
    notify_err "wl-copy ou wtype manquant."
    return 1
  fi

  set_state transcribing
  return 0
}

paste_transcript() {
  local text="$1"
  printf '%s' "$text" | wl-copy
  sleep 0.05
  # Ctrl+Shift+V: works in terminals (Ghostty) and most GUI apps
  wtype -M ctrl -M shift v -m shift -m ctrl
  set_state idle
}

# Stop whisper-stream, take last decoded step text, paste. No batch HTTP POST.
# Note: whisper-stream has no SIGINT flush of residual PCM; stop pastes the
# last completed step already written to -f (shortcut: last ~step window may
# be truncated, upgrade if upstream adds a clean shutdown decode).
stop_stream_flush_and_paste() {
  local stream_alive=0 stream_pid=""
  if [[ -f "$STREAM_PID_FILE" ]]; then
    stream_pid="$(tr -d '[:space:]' <"$STREAM_PID_FILE" || true)"
    if [[ -n "$stream_pid" ]] && kill -0 "$stream_pid" 2>/dev/null; then
      stream_alive=1
    fi
  fi

  # Snapshot before kill: shutdown wait used to append silence hallucinations.
  local text
  text="$(finalize_stream_text || true)"

  stop_stream_process

  if [[ "$(get_state)" != "transcribing" ]]; then
    return 0
  fi

  if ((stream_alive == 0)); then
    local err
    err="$(tail -n 8 "$STREAM_ERR_FILE" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
    set_state idle
    notify_err "STT / stream: ${err:-whisper-stream arrêté}"
    return 1
  fi

  if [[ -z "$text" ]]; then
    set_state idle
    return 0
  fi

  paste_transcript "$text"
}

stop_transcribe_and_paste() {
  if uses_streaming_stt; then
    stop_stream_flush_and_paste
    return
  fi

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
      *) notify_err "DICTATION_STT invalide: $STT_MODE"; return 1 ;;
    esac
  }

  local text rc
  set +e
  text="$(transcribe_routed 2>"$ERR_FILE")"
  rc=$?
  set -e

  if [[ "$(get_state)" != "transcribing" ]]; then
    return 0
  fi

  if [[ "$rc" -eq 2 ]]; then
    set_state idle
    return 0
  fi

  if [[ "$rc" -ne 0 ]]; then
    local err
    err="$(cat "$ERR_FILE" 2>/dev/null || echo "erreur inconnue")"
    set_state idle
    notify_err "STT / modèle: $err"
    return 1
  fi

  paste_transcript "$text"
}

cmd_stop() {
  if [[ "$(get_state)" != "listening" ]]; then
    stop_watchers
    exit 0
  fi
  # Freeze decoded text at key-up before we stall killing pw-record /
  # whisper-stream (those used to keep writing silence hallucinations).
  if uses_streaming_stt && [[ -f "$STREAM_OUT_FILE" ]]; then
    cp -f "$STREAM_OUT_FILE" "$STREAM_SNAPSHOT_FILE" || true
  fi
  stop_watchers

  ensure_state_dir
  LOCK_FILE="$STATE_DIR/lock"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    exec 9>&-
    exit 0
  fi

  stop_prepare_listening
  local prep_rc=$?
  release_lock

  if ((prep_rc == 2)); then
    exit 0
  fi
  if ((prep_rc != 0)); then
    exit "$prep_rc"
  fi

  stop_transcribe_and_paste
}

now_ms() {
  date +%s%3N
}

cmd_status() {
  if [[ "${1:-}" == "--json" ]]; then
    local state record_pid wav_bytes elapsed_ms rp
    state="$(get_state)"
    elapsed_ms=0
    if [[ "$state" == "listening" && -f "$LISTEN_STARTED_FILE" ]]; then
      local started now
      started="$(tr -d '[:space:]' <"$LISTEN_STARTED_FILE")"
      now="$(now_ms)"
      elapsed_ms=$((now - started))
    fi
    rp=null
    if [[ -f "$PID_FILE" ]]; then
      rp="$(tr -d '[:space:]' <"$PID_FILE")"
    fi
    wav_bytes=0
    if [[ -f "$WAV_FILE" ]]; then
      wav_bytes="$(stat -c '%s' "$WAV_FILE" 2>/dev/null || echo 0)"
    fi
    if command -v jq >/dev/null 2>&1; then
      jq -nc \
        --arg state "$state" \
        --argjson elapsed_ms "$elapsed_ms" \
        --arg rp "$rp" \
        --argjson wav_bytes "$wav_bytes" \
        --arg mode "$CFG_MODE" \
        '{state: $state, elapsed_ms: $elapsed_ms, record_pid: (if $rp == "null" then null else ($rp | tonumber) end), wav_bytes: $wav_bytes, mode: $mode}'
    else
      if [[ "$rp" == "null" ]]; then
        printf '{"state":"%s","elapsed_ms":%s,"record_pid":null,"wav_bytes":%s,"mode":"%s"}\n' \
          "$state" "$elapsed_ms" "$wav_bytes" "$CFG_MODE"
      else
        printf '{"state":"%s","elapsed_ms":%s,"record_pid":%s,"wav_bytes":%s,"mode":"%s"}\n' \
          "$state" "$elapsed_ms" "$rp" "$wav_bytes" "$CFG_MODE"
      fi
    fi
    return 0
  fi
  get_state
  echo
}

cmd_toggle() {
  case "$(get_state)" in
    listening) cmd_stop ;;
    transcribing)
      if worker_pid_alive "$STREAM_PID_FILE" || worker_pid_alive "$TRANSCRIBE_PID_FILE"; then
        exit 0
      fi
      set_state idle
      with_lock cmd_start
      ;;
    *) with_lock cmd_start ;;
  esac
}

force_stop_session() {
  stop_watchers
  stop_stream_process
  stop_recording_process
  if [[ -f "$TRANSCRIBE_PID_FILE" ]]; then
    stop_pid "$(tr -d '[:space:]' <"$TRANSCRIBE_PID_FILE")"
    rm -f "$TRANSCRIBE_PID_FILE"
  fi
  local p
  for p in $(pgrep -f 'whisper_cpp_transcribe|openai_transcribe|wyoming_transcribe|whisper-stream' 2>/dev/null || true); do
    stop_pid "$p"
  done
  set_state idle
}

cmd_force_stop() {
  ensure_state_dir
  if acquire_lock_wait 2; then
    force_stop_session
    release_lock
  else
    exec 9>&- 2>/dev/null || true
    force_stop_session
  fi
}

cmd_cancel() {
  cmd_force_stop
}

cmd_clean() {
  ensure_state_dir
  acquire_lock_wait 2
  local state
  state="$(get_state)"
  if [[ "$state" == "listening" || "$state" == "transcribing" ]]; then
    force_stop_session
  fi
  rm -f "$WAV_FILE" "$DATA_DIR"/*.wav 2>/dev/null || true
  rm -f "$PID_FILE" "$TRANSCRIBE_PID_FILE"
  release_lock
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
  DICTATION_BIN="${DICTATION_BIN:-$SCRIPT_DIR/dictation-ptt.sh}"
  WATCH_PID_FILE="$STATE_DIR/watch.pid"
  TRANSCRIBE_PID_FILE="$STATE_DIR/transcribe.pid"
  STREAM_PID_FILE="$STATE_DIR/stream.pid"
  case "${1:-}" in
    start) with_lock cmd_start ;;
    stop) cmd_stop ;;
    toggle) cmd_toggle ;;
    status) cmd_status "${2:-}" ;;
    force-stop) cmd_force_stop ;;
    cancel) cmd_cancel ;;
    clean) cmd_clean ;;
    reset) cmd_reset ;;
    *) usage ;;
  esac
}

main "$@"
