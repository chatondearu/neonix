#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-watch-$$"
export XDG_CONFIG_HOME="$XDG_RUNTIME_DIR/config"
export DICTATION_DATA_DIR="$XDG_RUNTIME_DIR/data"
export DICTATION_BIN="$ROOT/dictation-ptt.sh"
export DICTATION_CONFIG="$XDG_CONFIG_HOME/dictation-ptt/config.json"
export DICTATION_STT=wyoming
mkdir -p "$XDG_RUNTIME_DIR/bin" "$DICTATION_DATA_DIR" "$XDG_CONFIG_HOME/dictation-ptt"
export PATH="$XDG_RUNTIME_DIR/bin:$PATH"

mkdir -p "$XDG_CONFIG_HOME/dictation-ptt"
cat >"$XDG_CONFIG_HOME/dictation-ptt/config.json" <<'EOF'
{
  "silence_enabled": false,
  "max_duration_enabled": true,
  "max_sec": 2
}
EOF

cat >"$XDG_RUNTIME_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NOTIFY:$*" >>"${XDG_RUNTIME_DIR}/notify.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/notify-send"

cat >"$XDG_RUNTIME_DIR/bin/pw-record" <<'EOF'
#!/usr/bin/env bash
out="${@: -1}"
: >"$out"
printf 'RIFF' >"$out"
trap 'exit 0' INT TERM
sleep 300 &
wait
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/pw-record"

for c in wl-copy wtype curl; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$XDG_RUNTIME_DIR/bin/$c"
  chmod +x "$XDG_RUNTIME_DIR/bin/$c"
done

cat >"$XDG_RUNTIME_DIR/bin/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == *.py ]]; then
  echo "ok"
  exit 0
fi
echo "python3 stub: unsupported: $*" >&2
exit 1
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/python3"

if host_flock="$(PATH="${PATH#"$XDG_RUNTIME_DIR/bin:"}" command -v flock 2>/dev/null)"; then
  ln -sf "$host_flock" "$XDG_RUNTIME_DIR/bin/flock"
else
  printf '#!/usr/bin/env bash\nexit 0\n' >"$XDG_RUNTIME_DIR/bin/flock"
  chmod +x "$XDG_RUNTIME_DIR/bin/flock"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required for watcher test" >&2
  exit 1
fi

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening

sleep 8

"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle

echo OK
