#!/usr/bin/env bash
# Paste-once contract: start/stop writes wl-copy + wtype once, never while
# listening. Same-window lines (real containment) keep the latest rewrite;
# a shared 4-token prefix is not a window match (ADR-006).
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-paste-$$"
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

CLIP="$XDG_RUNTIME_DIR/clipboard.txt"
: >"$XDG_RUNTIME_DIR/wl-copy.log"
: >"$XDG_RUNTIME_DIR/wtype.log"
cat >"$XDG_RUNTIME_DIR/bin/wl-copy" <<EOF
#!/usr/bin/env bash
cat >"$CLIP"
echo "WLCOPY" >>"${XDG_RUNTIME_DIR}/wl-copy.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wl-copy"

cat >"$XDG_RUNTIME_DIR/bin/wtype" <<'EOF'
#!/usr/bin/env bash
echo "WTYPE:$*" >>"${XDG_RUNTIME_DIR}/wtype.log"
exit 0
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wtype"

install_stream() {
  cat >"$XDG_RUNTIME_DIR/bin/whisper-stream" <<'EOF'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
cat "${XDG_RUNTIME_DIR}/stream-fixture.txt" >"$out"
sleep 60
EOF
  chmod +x "$XDG_RUNTIME_DIR/bin/whisper-stream"
}

run_session() {
  rm -f "$CLIP" "$XDG_RUNTIME_DIR/wl-copy.log" "$XDG_RUNTIME_DIR/wtype.log"
  : >"$XDG_RUNTIME_DIR/wl-copy.log"
  : >"$XDG_RUNTIME_DIR/wtype.log"
  install_stream
  "$ROOT/dictation-ptt.sh" start
  "$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
  local live_wl live_wt
  live_wl="$(wc -l <"$XDG_RUNTIME_DIR/wl-copy.log")"
  live_wt="$(wc -l <"$XDG_RUNTIME_DIR/wtype.log")"
  "$ROOT/dictation-ptt.sh" stop
  "$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
  WLCOPY_COUNT="$(wc -l <"$XDG_RUNTIME_DIR/wl-copy.log")"
  WTYPE_COUNT="$(wc -l <"$XDG_RUNTIME_DIR/wtype.log")"
  CLIP_TEXT=""
  [[ -f "$CLIP" ]] && CLIP_TEXT="$(cat "$CLIP")"
  LIVE_WLCOPY="$live_wl"
  LIVE_WTYPE="$live_wt"
}

verdict() {
  local name="$1" expected="$2"
  local partials=no
  if [[ "$CLIP_TEXT" != "$expected" ]]; then
    partials=yes
  fi
  printf 'CASE=%s LIVE_WLCOPY=%s LIVE_WTYPE=%s WLCOPY=%s WTYPE=%s PARTIALS_PASTED=%s\n' \
    "$name" "$LIVE_WLCOPY" "$LIVE_WTYPE" "$WLCOPY_COUNT" "$WTYPE_COUNT" "$partials"
  printf 'EXPECTED=%s\n' "$expected"
  printf 'CLIPBOARD=%s\n' "$CLIP_TEXT"
  if [[ "$LIVE_WLCOPY" -ne 0 || "$LIVE_WTYPE" -ne 0 ]]; then
    echo "FAIL: paste while listening"
    return 1
  fi
  if [[ "$WLCOPY_COUNT" -ne 1 || "$WTYPE_COUNT" -ne 1 ]]; then
    echo "FAIL: paste count is not one"
    return 1
  fi
  if [[ "$partials" == yes ]]; then
    echo "FAIL: pasted text is not the final utterance"
    return 1
  fi
  echo "PASS"
}

failed=0

# Same-window prefix rewrites collapse to the latest line.
cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
bonjour
bonjour tout le
bonjour tout le monde
EOF
run_session
verdict prefix "bonjour tout le monde" || failed=1

# Shared 4-word prefix without containment: two windows, both kept.
cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
Il faut que je parte.
Il faut que je mange avant.
EOF
run_session
verdict prefix_collision "Il faut que je parte. Il faut que je mange avant." || failed=1

cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
C'est pour ça que je voulais tester.
C'est pour ça que ça marche pas.
EOF
run_session
verdict prefix_collision_longer_first "C'est pour ça que je voulais tester. C'est pour ça que ça marche pas." || failed=1

# Containment: later shorter rewrite wins (not the longer first line).
cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
Le chat est sur le tapis merci d
Le chat est sur le tapis
EOF
run_session
verdict latest_shorter "Le chat est sur le tapis" || failed=1

# Short French tokens must not match inside a previous word (Ça.→a in avant).
cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
Il faut que je mange avant.
Ça.
EOF
run_session
verdict short_ca "Il faut que je mange avant. Ça." || failed=1

cat >"$XDG_RUNTIME_DIR/stream-fixture.txt" <<'EOF'
C'est pour ça que je voulais tester.
Est.
EOF
run_session
verdict short_est "C'est pour ça que je voulais tester. Est." || failed=1

if [[ "$failed" -ne 0 ]]; then
  echo "LOOP=RED"
  exit 1
fi
echo "LOOP=GREEN"
