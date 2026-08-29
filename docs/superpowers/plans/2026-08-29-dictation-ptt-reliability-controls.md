# dictation-ptt Reliability + DMS Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make dictation-ptt leak-proof (locks, silence/max-duration auto-stop, recovery commands) and expose mode/keyboard/timeouts plus process controls in the DMS DictationPtt plugin, with ScrollLock bound via niri `dms/binds.kdl`.

**Architecture:** Keep bash `dictation-ptt` as the single engine. Add flock + watchers + `force-stop`/`cancel`/`clean`/`reset`/`status --json`. DMS plugin writes `~/.config/dictation-ptt/config.json` and regenerates `~/.config/niri/dms/binds.kdl` (already optionally included by `desktop/niri/config.kdl`). Stream Deck fragments stay mode-aware.

**Tech Stack:** bash, flock, ffmpeg (silence energy), Python STT clients (unchanged), DMS Quickshell PluginComponent/PluginSettings, niri KDL binds, Nix wrapper PATH.

**Spec:** `docs/superpowers/specs/2026-08-29-dictation-ptt-reliability-controls-design.md`

## Global Constraints

- CLI remains the only process that starts/stops `pw-record` and runs STT
- States exactly: `idle` | `listening` | `transcribing`
- Defaults: mode `hold`, key `ScrollLock`, `silence_ms=2500`, `max_sec=180`, both auto-stops enabled
- WAV under `/tmp/dictation-ptt-$UID/`; state/lock under `$XDG_RUNTIME_DIR/dictation-ptt/`
- Paste: `wtype` Ctrl+Shift+V; notify title `Dictation`, replace-id `991031`
- `toggle` while `transcribing`: no-op exit 0 (DMS disables click); never start a second session
- English code comments; French notify strings OK
- Conventional Commits
- No flake.lock update in this workstream

## File structure

| Path | Responsibility |
|------|----------------|
| `scripts/ai/dictation-ptt/dictation-ptt.sh` | Lifecycle, flock, watchers, recovery cmds, config load, status JSON |
| `scripts/ai/dictation-ptt/silence-watch.sh` | Optional helper: poll WAV energy → exit 0 when silence long enough (invoked by main) |
| `scripts/ai/dictation-ptt/test_dictation_state.sh` | Extend shell integration tests |
| `scripts/ai/dictation-ptt/test_recovery.sh` | force-stop / clean / lock tests |
| `scripts/ai/dictation-ptt/streamcontroller/stt-key.json` | Hold fragment (keep) |
| `scripts/ai/dictation-ptt/streamcontroller/stt-key-toggle.json` | Toggle fragment |
| `scripts/ai/dictation-ptt/README.md` | Document commands, config, ScrollLock, DMS |
| `pkgs/dictation-ptt/default.nix` | Add `ffmpeg`, `util-linux` (flock) to PATH |
| `desktop/dank-material-shell/plugins/DictationPtt/plugin.json` | settings + permissions |
| `desktop/dank-material-shell/plugins/DictationPtt/DictationPtt.qml` | status JSON, disable click while transcribing, actions |
| `desktop/dank-material-shell/plugins/DictationPtt/DictationPttSettings.qml` | Mode, key, silence, max duration, action buttons |
| `desktop/niri/binds.kdl` or docs only | Prefer runtime `dms/binds.kdl`; optional static ScrollLock fallback comment in README |

---

### Task 1: Config load + flock + recovery commands

**Files:**
- Modify: `scripts/ai/dictation-ptt/dictation-ptt.sh`
- Create: `scripts/ai/dictation-ptt/test_recovery.sh`
- Modify: `pkgs/dictation-ptt/default.nix` (add `util-linux` for `flock`)

**Interfaces:**
- Consumes: existing `STATE_DIR`, `DATA_DIR`, `stop_recording_process`
- Produces:
  - `CONFIG_FILE` default `$XDG_CONFIG_HOME/dictation-ptt/config.json` (fallback `$HOME/.config/dictation-ptt/config.json`)
  - `load_config` sets `CFG_MODE`, `CFG_SILENCE_ENABLED`, `CFG_SILENCE_MS`, `CFG_MAX_ENABLED`, `CFG_MAX_SEC`, `CFG_KEYBOARD_KEY`
  - `with_lock` wrapper using `flock -n 9` on `$STATE_DIR/lock` for mutating cmds
  - Commands: `force-stop`, `cancel`, `clean`, `reset`
  - `TRANSCRIBE_PID_FILE="$STATE_DIR/transcribe.pid"` written around STT python invocations

- [ ] **Step 1: Write failing recovery test**

Create `scripts/ai/dictation-ptt/test_recovery.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-rec-$$"
export XDG_CONFIG_HOME="$XDG_RUNTIME_DIR/config"
export DICTATION_DATA_DIR="$XDG_RUNTIME_DIR/data"
mkdir -p "$XDG_RUNTIME_DIR/bin" "$DICTATION_DATA_DIR" "$XDG_CONFIG_HOME"
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
for c in wl-copy wtype curl flock; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$XDG_RUNTIME_DIR/bin/$c"
  chmod +x "$XDG_RUNTIME_DIR/bin/$c"
done
# Real flock preferred if present on host PATH ahead of stub — put util-linux first when available
if command -v flock >/dev/null 2>&1; then
  ln -sf "$(command -v flock)" "$XDG_RUNTIME_DIR/bin/flock"
fi

"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | grep -qx idle && exit 1 || true
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx listening
"$ROOT/dictation-ptt.sh" force-stop
"$ROOT/dictation-ptt.sh" status | head -1 | grep -qx idle
test ! -f "$DICTATION_DATA_DIR/capture.wav" -o ! -s "$DICTATION_DATA_DIR/capture.wav" || \
  { "$ROOT/dictation-ptt.sh" clean; test ! -e "$DICTATION_DATA_DIR/capture.wav" || ! -s "$DICTATION_DATA_DIR/capture.wav"; }
echo OK
```

Make executable. Run:

```bash
bash scripts/ai/dictation-ptt/test_recovery.sh
```

Expected: FAIL (`force-stop` unknown / usage).

- [ ] **Step 2: Implement config + lock + recovery in `dictation-ptt.sh`**

Add near top (after path vars):

```bash
CONFIG_FILE="${DICTATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt/config.json}"
LOCK_FILE=""
WATCH_PID_FILE=""
TRANSCRIBE_PID_FILE=""

load_config() {
  CFG_MODE=hold
  CFG_KEYBOARD_KEY=ScrollLock
  CFG_SILENCE_ENABLED=true
  CFG_SILENCE_MS=2500
  CFG_MAX_ENABLED=true
  CFG_MAX_SEC=180
  [[ -f "$CONFIG_FILE" ]] || return 0
  # Prefer jq if present; else python one-liner
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

cmd_force_stop() {
  ensure_state_dir
  stop_watchers
  stop_recording_process
  if [[ -f "$TRANSCRIBE_PID_FILE" ]]; then
    stop_pid "$(tr -d '[:space:]' <"$TRANSCRIBE_PID_FILE")"
    rm -f "$TRANSCRIBE_PID_FILE"
  fi
  # Session STT clients only
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
```

Wire `main`:

```bash
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
```

Update `usage` string accordingly. Stub `stop_watchers` as no-op until Task 2.

Change `cmd_toggle` transcribing branch to exit 0 (no-op).

In `cmd_stop`, when launching python STT, record PID:

```bash
# example pattern around transcription
python3 ... &
echo $! >"$TRANSCRIBE_PID_FILE"
wait "$(cat "$TRANSCRIBE_PID_FILE")"
rm -f "$TRANSCRIBE_PID_FILE"
```

(Or use a wrapper function `run_tracked`.)

- [ ] **Step 3: Update package PATH**

In `pkgs/dictation-ptt/default.nix`, add `util-linux` (and later ffmpeg in Task 2) to `makeBinPath`.

- [ ] **Step 4: Re-run recovery test**

```bash
bash scripts/ai/dictation-ptt/test_recovery.sh
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add scripts/ai/dictation-ptt/dictation-ptt.sh scripts/ai/dictation-ptt/test_recovery.sh pkgs/dictation-ptt/default.nix
git commit -m "$(cat <<'EOF'
feat(dictation-ptt): add flock and recovery commands

Prevent stacked sessions and allow force-stop/clean/reset without
leaving orphan recorders or stale state.
EOF
)"
```

---

### Task 2: Silence + max-duration watchers

**Files:**
- Create: `scripts/ai/dictation-ptt/silence-watch.sh`
- Modify: `scripts/ai/dictation-ptt/dictation-ptt.sh`
- Modify: `scripts/ai/dictation-ptt/test_recovery.sh` (or new `test_watchers.sh`)
- Modify: `pkgs/dictation-ptt/default.nix` (add `ffmpeg`)

**Interfaces:**
- Consumes: `WAV_FILE`, `CFG_SILENCE_*`, `CFG_MAX_*`, `cmd_stop` via invoking `dictation-ptt stop` (full path / `$0`)
- Produces: `start_watchers` / `stop_watchers`; child PID in `$WATCH_PID_FILE`

- [ ] **Step 1: Write failing watcher test**

Create `scripts/ai/dictation-ptt/test_watchers.sh` that:

1. Writes config with `silence_enabled=false`, `max_duration_enabled=true`, `max_sec=2`
2. Stubs `pw-record` to append silence forever (or sleep)
3. Stubs STT python to echo `ok`
4. Runs `start`, sleeps 3s, expects state `idle` (max duration triggered stop)

Run; expect FAIL until watchers exist.

- [ ] **Step 2: Implement `silence-watch.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Args: wav_path silence_ms max_sec silence_enabled max_enabled stop_cmd
# Poll every 200ms. For silence: use ffmpeg astats/volumedetect on last ~0.3s of WAV
# when file size is growing; if RMS below threshold for silence_ms → exec stop_cmd
# If elapsed >= max_sec and max_enabled → exec stop_cmd
```

Concrete silence check (v1 threshold fixed):

```bash
# Returns 0 if last chunk is "quiet"
ffmpeg -v error -sseof -0.3 -i "$wav" -af "volumedetect" -f null - 2>&1 \
  | awk '/mean_volume:/ { if ($3+0 < -40) exit 0; else exit 1 }'
```

If ffmpeg fails (file too short), treat as not-yet-silent.

- [ ] **Step 3: Hook watchers from `cmd_start`**

```bash
start_watchers() {
  stop_watchers
  local self="${DICTATION_BIN:-dictation-ptt}"
  (
    # max duration
    if [[ "$CFG_MAX_ENABLED" == "true" ]]; then
      sleep "$CFG_MAX_SEC"
      "$self" stop || true
      exit 0
    fi
  ) &
  local max_pid=$!
  (
    [[ "$CFG_SILENCE_ENABLED" == "true" ]] || exit 0
    # wait for non-empty wav then run silence-watch.sh which calls stop
    bash "$SCRIPT_DIR/silence-watch.sh" "$WAV_FILE" "$CFG_SILENCE_MS" "$self"
  ) &
  local sil_pid=$!
  printf '%s %s\n' "$max_pid" "$sil_pid" >"$WATCH_PID_FILE"
}

stop_watchers() {
  [[ -f "$WATCH_PID_FILE" ]] || return 0
  local p
  for p in $(tr -d '\n' <"$WATCH_PID_FILE"); do
    stop_pid "$p"
  done
  rm -f "$WATCH_PID_FILE"
}
```

Call `start_watchers` at end of `cmd_start`. Call `stop_watchers` at beginning of `cmd_stop` / `cmd_force_stop` (before stopping recorder is OK).

**Race note:** max-duration sleeper must not fire `stop` after user already stopped — `cmd_stop` should be idempotent when state is not `listening` (early exit).

Update `cmd_stop` start:

```bash
[[ "$(get_state)" == "listening" ]] || { stop_watchers; exit 0; }
stop_watchers
```

- [ ] **Step 4: Package ffmpeg + run tests**

```bash
bash scripts/ai/dictation-ptt/test_dictation_state.sh
bash scripts/ai/dictation-ptt/test_recovery.sh
bash scripts/ai/dictation-ptt/test_watchers.sh
```

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(dictation-ptt): auto-stop on silence and max duration

Cap runaway recordings that previously filled RAM when hold release
was missed.
EOF
)"
```

---

### Task 3: `status --json`

**Files:**
- Modify: `scripts/ai/dictation-ptt/dictation-ptt.sh`
- Modify: `scripts/ai/dictation-ptt/test_dictation_state.sh`

**Interfaces:**
- Produces: `dictation-ptt status --json` → one JSON object on stdout:

```json
{"state":"idle","elapsed_ms":0,"record_pid":null,"wav_bytes":0,"mode":"hold"}
```

- [ ] **Step 1: Extend shell test** asserting `status --json` contains `"state":"listening"` after start

- [ ] **Step 2: Implement `cmd_status`**

If `$1` is `--json`, print JSON via `jq -n` or printf; else keep plain word + newline.

Track `LISTEN_STARTED_FILE="$STATE_DIR/listening_started"` (epoch ms) set in `cmd_start`, cleared on idle.

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(dictation-ptt): add status --json for DMS polling"
```

---

### Task 4: DMS plugin settings + actions + safer click

**Files:**
- Modify: `desktop/dank-material-shell/plugins/DictationPtt/plugin.json`
- Modify: `desktop/dank-material-shell/plugins/DictationPtt/DictationPtt.qml`
- Create: `desktop/dank-material-shell/plugins/DictationPtt/DictationPttSettings.qml`

**Interfaces:**
- Consumes: `dictation-ptt status --json`, recovery commands
- Produces: writes `~/.config/dictation-ptt/config.json` on settings change; regenerates niri binds file (Task 5 can own bind writer — call shared helper script)

- [ ] **Step 1: Update `plugin.json`**

```json
{
  "id": "dictationPtt",
  "name": "Dictation PTT",
  "description": "Dictation status, hold/toggle, shortcuts, and recovery controls",
  "version": "0.2.0",
  "author": "chaton",
  "icon": "mic",
  "type": "widget",
  "component": "./DictationPtt.qml",
  "settings": "./DictationPttSettings.qml",
  "capabilities": ["dankbar-widget"],
  "permissions": ["settings_read", "settings_write"]
}
```

- [ ] **Step 2: Settings UI**

Mirror `emojiLauncher` patterns (`PluginSettings`, `StringSetting`, `ToggleSetting`). Keys:

- `mode` (`hold`/`toggle`) — use StringSetting or two toggles; store string
- `keyboard_key` default `ScrollLock`
- `silence_enabled`, `silence_ms`
- `max_duration_enabled`, `max_sec`

On any save, run detached:

```bash
dictation-ptt-write-config   # OR inline: python/jq write config.json then bind sync script
```

Prefer a small script `scripts/ai/dictation-ptt/sync-config-from-dms.sh` that reads DMS plugin settings JSON if accessible; **simpler v1:** Settings QML writes config file directly via `Quickshell.execDetached` calling:

```bash
bash -c 'mkdir -p ~/.config/dictation-ptt && printf "%s" "$JSON" > ~/.config/dictation-ptt/config.json'
```

Plus call bind sync from Task 5.

Add action buttons (Process / execDetached):

- Force stop → `dictation-ptt force-stop`
- Cancel → `dictation-ptt cancel`
- Clean → `dictation-ptt clean`
- Reset → `dictation-ptt reset`
- Restart backends → `systemctl restart parakeet-asr whisper-cpp-asr` (best-effort; ignore failures)

- [ ] **Step 3: Update widget QML**

- Poll `["dictation-ptt", "status", "--json"]` and parse `state`
- `pillClickAction`: if `transcribing` return; else `toggle`

- [ ] **Step 4: Manual check** — restart DMS, open plugin settings, verify file written

```bash
systemctl --user restart dms
cat ~/.config/dictation-ptt/config.json
```

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(dms): dictation settings and recovery actions

Expose hold/toggle timeouts and force-stop/clean in DictationPtt.
EOF
)"
```

---

### Task 5: niri ScrollLock bind via `dms/binds.kdl`

**Files:**
- Create: `scripts/ai/dictation-ptt/sync-niri-bind.sh`
- Modify: `DictationPttSettings.qml` to call sync on save
- Modify: `scripts/ai/dictation-ptt/README.md`

**Interfaces:**
- Reads `config.json` `mode` + `keyboard_key`
- Writes `~/.config/niri/dms/binds.kdl` (optional include already in `desktop/niri/config.kdl:294`)

- [ ] **Step 1: Implement sync script**

```bash
#!/usr/bin/env bash
set -euo pipefail
CFG="${DICTATION_CONFIG:-$HOME/.config/dictation-ptt/config.json}"
OUT="${NIRI_DMS_BINDS:-$HOME/.config/niri/dms/binds.kdl}"
MODE=hold
KEY=ScrollLock
[[ -f "$CFG" ]] && MODE=$(jq -r '.mode // "hold"' "$CFG") && KEY=$(jq -r '.keyboard_key // "ScrollLock"' "$CFG")
mkdir -p "$(dirname "$OUT")"
BIN=/run/current-system/sw/bin/dictation-ptt
if [[ "$MODE" == "toggle" ]]; then
  cat >"$OUT" <<EOF
binds {
    ${KEY} allow-when-locked=true hotkey-overlay-title="Dictation toggle" { spawn "$BIN" "toggle"; }
}
EOF
else
  cat >"$OUT" <<EOF
binds {
    ${KEY} allow-when-locked=true hotkey-overlay-title="Dictation hold" { spawn "$BIN" "start"; }
    ${KEY}+Release allow-when-locked=true hotkey-overlay-title=null { spawn "$BIN" "stop"; }
}
EOF
fi
# Hint reload — niri may pick include on config reload
niri msg action do-screen-transition 2>/dev/null || true
echo "Wrote $OUT (mode=$MODE key=$KEY). Reload niri config if binds inactive."
```

Verify niri supports `Key+Release` syntax for the running version; if not, document toggle-only fallback for keyboard and keep hold on Stream Deck only. **Validation step:** check `niri validate` / docs for release binds before committing; if unsupported, use:

- hold mode keyboard → still `toggle` with notify “release unsupported; use toggle” **OR** bind only press→start and rely on silence/max-duration for stop (acceptable per spec safety nets).

Record the chosen niri-capable approach in README.

- [ ] **Step 2: Default config bootstrap**

On first DMS settings open or package activation, ensure default `config.json` + run sync once (can be done from Settings `Component.onCompleted`).

- [ ] **Step 3: Manual test ScrollLock**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(dictation-ptt): sync ScrollLock bind into niri dms/binds.kdl"
```

---

### Task 6: Stream Deck mode fragments + README

**Files:**
- Keep: `streamcontroller/stt-key.json` (hold)
- Create: `streamcontroller/stt-key-toggle.json`
- Modify: `streamcontroller/install-stt-key.sh` to accept `--mode hold|toggle` reading config by default
- Modify: `README.md`
- Update snapshot if needed

- [ ] **Step 1: Add toggle fragment** (single RunCommand `toggle`)

- [ ] **Step 2: install script selects fragment from config `mode`**

- [ ] **Step 3: README sections** — recovery cmds, config keys, silence/max, ScrollLock, DMS settings, troubleshooting stuck RAM

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(dictation-ptt): document controls and mode-aware Stream Deck install"
```

---

### Task 7: Rebuild package + smoke on machine

**Files:** none new

- [ ] **Step 1: Rebuild/switch only dictation-related closure**

```bash
sudo nixos-rebuild switch --flake .#neo-nix
```

(Expect no flake update.)

- [ ] **Step 2: Smoke checklist from spec**

1. `dictation-ptt reset` while idle → OK  
2. Hold ScrollLock / Deck: start/stop, no orphan `pw-record`  
3. Silence auto-stop  
4. Max duration (temporarily set `max_sec=5` in config)  
5. DMS Force stop / Clean  
6. No stacked bash on spam toggle  

- [ ] **Step 3: Final commit only if smoke fixes needed**

---

## Spec coverage check

| Spec requirement | Task |
|------------------|------|
| flock / single session | 1 |
| force-stop / cancel / clean / reset | 1 |
| silence auto-stop configurable | 2 + 4 |
| max duration | 2 + 4 |
| status --json | 3 |
| DMS settings + actions | 4 |
| ScrollLock + configurable key via niri | 5 |
| Stream Deck mode-aware | 6 |
| README / ops | 6–7 |
| Paste Ctrl+Shift+V | unchanged (keep) |
| No flake update | 7 constraint |

## Placeholder / consistency review

- Key names unified: `silence_ms`, `max_sec`, `max_duration_enabled`, `keyboard_key`, `mode`
- Recovery command names match DMS buttons
- Watchers always stopped before/with force-stop
