#!/usr/bin/env bash
# Self-check: start consumes PCM via whisper-stream before stop; stop does not
# POST a full WAV to batch /audio/transcriptions or /inference.
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-stream-$$"
export XDG_CONFIG_HOME="$XDG_RUNTIME_DIR/config"
export DICTATION_DATA_DIR="$XDG_RUNTIME_DIR/data"
export DICTATION_STT=auto
export DICTATION_STREAM_MODEL="$XDG_RUNTIME_DIR/fake-model.bin"
export DICTATION_STREAM_BIN=whisper-stream
mkdir -p "$XDG_RUNTIME_DIR/bin" "$DICTATION_DATA_DIR" "$XDG_CONFIG_HOME/dictation-ptt"
export PATH="$XDG_RUNTIME_DIR/bin:$PATH"
: >"$DICTATION_STREAM_MODEL"

cat >"$XDG_CONFIG_HOME/dictation-ptt/config.json" <<'EOF'
{"silence_enabled": false, "max_duration_enabled": false}
EOF

cat >"$XDG_RUNTIME_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NOTIFY:$*" >>"${XDG_RUNTIME_DIR}/notify.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/notify-send"

cat >"$XDG_RUNTIME_DIR/bin/pw-record" <<'EOF'
#!/usr/bin/env bash
out="${@: -1}"
le32() { printf "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(( $1 & 255 )) $(( ($1 >> 8) & 255 )) $(( ($1 >> 16) & 255 )) $(( ($1 >> 24) & 255 )))"; }
le16() { printf "$(printf '\\x%02x\\x%02x' $(( $1 & 255 )) $(( ($1 >> 8) & 255 )))"; }
{
  printf 'RIFF'; le32 32036; printf 'WAVEfmt '; le32 16; le16 1; le16 1
  le32 16000; le32 32000; le16 2; le16 16; printf 'data'; le32 32000
  dd if=/dev/zero bs=32000 count=1 status=none 2>/dev/null || head -c 32000 </dev/zero
} >"$out"
sleep 60
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/pw-record"

cat >"$XDG_RUNTIME_DIR/bin/whisper-stream" <<'EOF'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
: >"${XDG_RUNTIME_DIR}/stream-pcm-consumed"
# Mimic whisper-stream step>0: each line is a full-window rewrite.
{
  printf 'bonjour\n'
  printf 'bonjour tout le\n'
  printf 'bonjour tout le monde\n'
} >"$out"
# Prove PCM consumer is alive while listening (before stop).
while true; do
  echo tick >>"${XDG_RUNTIME_DIR}/stream-pcm-consumed"
  sleep 0.1
done
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/whisper-stream"

# Batch helpers must not run on the streaming happy path.
cat >"$XDG_RUNTIME_DIR/bin/python3" <<'EOF'
#!/usr/bin/env bash
echo "BATCH_PYTHON:$*" >>"${XDG_RUNTIME_DIR}/batch.log"
echo "batch should not run" >&2
exit 1
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/python3"

cat >"$XDG_RUNTIME_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "BATCH_CURL:$*" >>"${XDG_RUNTIME_DIR}/batch.log"
exit 1
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/curl"

CLIP="$XDG_RUNTIME_DIR/clipboard.txt"
cat >"$XDG_RUNTIME_DIR/bin/wl-copy" <<EOF
#!/usr/bin/env bash
cat >"$CLIP"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wl-copy"

cat >"$XDG_RUNTIME_DIR/bin/wtype" <<'EOF'
#!/usr/bin/env bash
echo "WTYPE:$*" >>"${XDG_RUNTIME_DIR}/wtype.log"
exit 0
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wtype"

STATE_DIR="$XDG_RUNTIME_DIR/dictation-ptt"

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
test -f "$STATE_DIR/stream.pid"
stream_pid="$(tr -d '[:space:]' <"$STATE_DIR/stream.pid")"
kill -0 "$stream_pid" 2>/dev/null

# While listening, streaming consumer must already be reading/ticking.
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if [[ -f "$XDG_RUNTIME_DIR/stream-pcm-consumed" ]] && [[ "$(wc -l <"$XDG_RUNTIME_DIR/stream-pcm-consumed")" -ge 2 ]]; then
    break
  fi
  sleep 0.1
done
test "$(wc -l <"$XDG_RUNTIME_DIR/stream-pcm-consumed")" -ge 2

"$ROOT/dictation-ptt.sh" stop
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
test ! -f "$STATE_DIR/stream.pid"
# Same-window drafts collapse to the latest rewrite (not joined).
grep -qx 'bonjour tout le monde' "$CLIP"
test ! -f "$XDG_RUNTIME_DIR/batch.log"
test ! -f "$XDG_RUNTIME_DIR/notify.log"

# Trailing Whisper junk must not be pasted; SIGINT-deaf stream must die fast.
rm -f "$CLIP"
cat >"$XDG_RUNTIME_DIR/bin/whisper-stream" <<'EOF'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
{
  printf '%s\n' "J'essaye de faire des trucs."
  printf '%s\n' '...'
  printf '%s\n' '[Musique]'
  printf '%s\n' '...'
  printf '%s\n' "Sous-titres réalisés par la communauté d'Amara.org"
  printf '%s\n' "Le modèle a l'air de couper au"
  printf '%s\n' "Le modèle a l'air de couper au bout d'un certain temps."
  printf '%s\n' 'ce que je dis.'
  printf '%s\n' '...'
} >"$out"
trap '' INT TERM
sleep 30
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/whisper-stream"

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
stop_started="$SECONDS"
"$ROOT/dictation-ptt.sh" stop
stop_elapsed=$((SECONDS - stop_started))
test "$stop_elapsed" -le 2
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
grep -qx "J'essaye de faire des trucs. Le modèle a l'air de couper au bout d'un certain temps. ce que je dis." "$CLIP"
test ! -f "$XDG_RUNTIME_DIR/batch.log"

# Stream crash after start → critical notify on stop (no silent idle).
rm -f "$CLIP" "$XDG_RUNTIME_DIR/notify.log" "$XDG_RUNTIME_DIR/batch.log"
cat >"$XDG_RUNTIME_DIR/bin/whisper-stream" <<'EOF'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
echo "init failed: no capture" >>"${XDG_RUNTIME_DIR}/dictation-ptt/stream.err"
sleep 0.3
exit 1
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/whisper-stream"

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
sleep 0.5
set +e
"$ROOT/dictation-ptt.sh" stop
stop_rc=$?
set -e
test "$stop_rc" -ne 0
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
grep -q "stream\|STT" "$XDG_RUNTIME_DIR/notify.log"
test ! -f "$XDG_RUNTIME_DIR/batch.log"

echo OK
