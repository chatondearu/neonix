#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-rec-$$"
export XDG_CONFIG_HOME="$XDG_RUNTIME_DIR/config"
export DICTATION_DATA_DIR="$XDG_RUNTIME_DIR/data"
mkdir -p "$XDG_RUNTIME_DIR/bin" "$DICTATION_DATA_DIR" "$XDG_CONFIG_HOME/dictation-ptt"
cat >"$XDG_CONFIG_HOME/dictation-ptt/config.json" <<'EOF'
{"silence_enabled": false}
EOF
export PATH="$XDG_RUNTIME_DIR/bin:$PATH"

# Minimal stubs (reuse patterns from test_dictation_state.sh)
cat >"$XDG_RUNTIME_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NOTIFY:$*" >>"${XDG_RUNTIME_DIR}/notify.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/notify-send"
cp "$ROOT/test_dictation_state.sh" /dev/null 2>/dev/null || true
# Inline minimal pw-record stub that sleeps
cat >"$XDG_RUNTIME_DIR/bin/pw-record" <<'EOF'
#!/usr/bin/env bash
out="${@: -1}"
: >"$out"
printf 'RIFF' >"$out"
sleep 60
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/pw-record"
for c in wl-copy wtype curl; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$XDG_RUNTIME_DIR/bin/$c"
  chmod +x "$XDG_RUNTIME_DIR/bin/$c"
done
# Real flock preferred if present on host PATH ahead of stub — put util-linux first when available
if host_flock="$(PATH="${PATH#"$XDG_RUNTIME_DIR/bin:"}" command -v flock 2>/dev/null)"; then
  ln -sf "$host_flock" "$XDG_RUNTIME_DIR/bin/flock"
else
  printf '#!/usr/bin/env bash\nexit 0\n' >"$XDG_RUNTIME_DIR/bin/flock"
  chmod +x "$XDG_RUNTIME_DIR/bin/flock"
fi

STATE_DIR="$XDG_RUNTIME_DIR/dictation-ptt"

# clean while listening: stops recorder and returns idle
"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
rec_pid="$(tr -d '[:space:]' <"$STATE_DIR/record.pid")"
test -n "$rec_pid"
kill -0 "$rec_pid" 2>/dev/null
"$ROOT/dictation-ptt.sh" clean
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
! kill -0 "$rec_pid" 2>/dev/null
test ! -f "$STATE_DIR/record.pid"
test ! -e "$DICTATION_DATA_DIR/capture.wav" || ! -s "$DICTATION_DATA_DIR/capture.wav"

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | grep -qx idle && exit 1 || true
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
"$ROOT/dictation-ptt.sh" force-stop
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
test ! -f "$DICTATION_DATA_DIR/capture.wav" -o ! -s "$DICTATION_DATA_DIR/capture.wav" || \
  { "$ROOT/dictation-ptt.sh" clean; test ! -e "$DICTATION_DATA_DIR/capture.wav" || ! -s "$DICTATION_DATA_DIR/capture.wav"; }

# force-stop during transcribing (simulated in-flight STT)
"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
sleep 300 &
fake_stt=$!
disown "$fake_stt" 2>/dev/null || true
printf '%s\n' "$fake_stt" >"$STATE_DIR/transcribe.pid"
printf 'transcribing\n' >"$STATE_DIR/state"
"$ROOT/dictation-ptt.sh" force-stop
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
kill "$fake_stt" 2>/dev/null || true
wait "$fake_stt" 2>/dev/null || true
test ! -f "$STATE_DIR/transcribe.pid"

echo OK
