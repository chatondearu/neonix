#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-test-$$"
mkdir -p "$XDG_RUNTIME_DIR"
export PATH="$XDG_RUNTIME_DIR/bin:$PATH"
mkdir -p "$XDG_RUNTIME_DIR/bin"

cat >"$XDG_RUNTIME_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NOTIFY:$*" >>"${XDG_RUNTIME_DIR}/notify.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/notify-send"

cat >"$XDG_RUNTIME_DIR/bin/pw-record" <<'EOF'
#!/usr/bin/env bash
out="${@: -1}"
# Minimal 16 kHz mono s16 WAV (1 s silence) without python3
le32() { printf "$(printf '\\x%02x\\x%02x\\x%02x\\x%02x' $(( $1 & 255 )) $(( ($1 >> 8) & 255 )) $(( ($1 >> 16) & 255 )) $(( ($1 >> 24) & 255 )))"; }
le16() { printf "$(printf '\\x%02x\\x%02x' $(( $1 & 255 )) $(( ($1 >> 8) & 255 )))"; }
{
  printf 'RIFF'
  le32 32036
  printf 'WAVEfmt '
  le32 16
  le16 1
  le16 1
  le32 16000
  le32 32000
  le16 2
  le16 16
  printf 'data'
  le32 32000
  dd if=/dev/zero bs=32000 count=1 status=none 2>/dev/null || head -c 32000 </dev/zero
} >"$out"
sleep 30
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/pw-record"

cat >"$XDG_RUNTIME_DIR/bin/wl-copy" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wl-copy"

cat >"$XDG_RUNTIME_DIR/bin/wtype" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/wtype"

cat >"$XDG_RUNTIME_DIR/bin/python3" <<'EOF'
#!/usr/bin/env bash
# Stub python3 for tests: fake transcribe scripts print a fixed transcript.
if [[ "${1:-}" == *.py ]]; then
  echo "bonjour"
  exit 0
fi
echo "python3 stub: unsupported: $*" >&2
exit 1
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/python3"

export DICTATION_TRANSCRIBE="$XDG_RUNTIME_DIR/fake_transcribe.py"
cat >"$DICTATION_TRANSCRIBE" <<'EOF'
#!/usr/bin/env python3
import sys

print("bonjour")
sys.exit(0)
EOF
chmod +x "$DICTATION_TRANSCRIBE"

"$ROOT/dictation-ptt.sh" status | grep -qx idle
"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | grep -qx listening
grep -q "Écoute" "$XDG_RUNTIME_DIR/notify.log"
"$ROOT/dictation-ptt.sh" stop
"$ROOT/dictation-ptt.sh" status | grep -qx idle
grep -q "Transcription" "$XDG_RUNTIME_DIR/notify.log"
echo OK
