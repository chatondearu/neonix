# Design: dictation-ptt reliability, keyboard bind, DMS controls

Date: 2026-08-29  
Status: approved for planning  
Extends: `2026-08-03-dictation-ptt-v2-fast-stt-ui-design.md`, `2026-08-03-streamdeck-ptt-stt-design.md`

## Goal

Make local dictation reliable under hold-to-talk and toggle, and give the user controllable triggers and recovery tools:

1. **Reliable process lifecycle** — release / stop always ends recording; no orphan `pw-record` or stacked `dictation-ptt` instances; no unbounded WAV / RAM growth
2. **Configurable trigger mode** — `hold` or `toggle`, chosen in the DMS DictationPtt plugin
3. **Keyboard shortcut** — default `ScrollLock`, reconfigurable in DMS; wired through niri binds
4. **Silence auto-stop** — after configurable quiet period while listening, stop and transcribe
5. **Max recording duration** — hard safety cut (anti-RAM)
6. **Operator controls in DMS** — force stop, cancel transcription, clean cache, reset; plus restart of local STT user/system services when available without new privilege escalation

## Non-goals (v1)

- Waveform / live meter UI
- Changing STT backend selection from DMS (keep `DICTATION_STT` / env)
- New privileged polkit helpers beyond what already works for service restart
- Fixing unrelated packages (`gitnexus`, flake lock updates)
- Replacing Stream Deck or DMS click with a different primary UX

## Problem evidence (2026-08-29)

Observed stuck session:

- State file stuck at `transcribing`
- Multiple concurrent `dictation-ptt.sh toggle` bash processes
- WAV under `/tmp/dictation-ptt-$UID/` ~93 MiB while listening failed to stop cleanly
- `parakeet` RSS ~4 GiB with `-long-audio` chewing a huge clip
- Stream Deck live page correctly mapped to hold `start`/`stop`, while DMS bar still calls `toggle` — races when both are used or when stop is missed

Root causes to address in design:

- No exclusive lock across start/stop/toggle
- Stop path not always killing recorders / not canceling in-flight work
- No silence or max-duration watchers during `listening`
- DMS can fire `toggle` while already `transcribing`
- No first-class recovery commands for the user

## Architecture

Approach: **CLI as single engine + DMS settings/actions + external triggers**.

```text
  ScrollLock (niri) ──┐
  Stream Deck ────────┤
  DMS pill click ─────┼──► dictation-ptt CLI ──► wl-copy + wtype Ctrl+Shift+V
  DMS menu actions ───┘         │
                                ├── flock + state machine
                                ├── silence + max-duration watchers
                                └── STT backends (unchanged auto chain)

  DMS settings ──write──► config file/env consumed by CLI
               ──update─► niri keybind snippet / reload hint
```

| Layer | Responsibility |
|-------|----------------|
| `dictation-ptt` CLI | Source of truth for lifecycle, locks, watchers, recovery commands, status |
| DMS plugin `DictationPtt` | Settings UI, status pill, action menu; writes CLI config; updates keyboard bind |
| Triggers | niri (keyboard), StreamController (Deck), DMS click |

Shared paths (keep current split):

- `STATE_DIR`: `${XDG_RUNTIME_DIR}/dictation-ptt` — state, PID, lock
- `DATA_DIR`: `/tmp/dictation-ptt-$UID` — WAV only (avoid filling session tmpfs)

## CLI design

### State machine

States: `idle` → `listening` → `transcribing` → `idle`.

Transitions:

| From | Event | To | Notes |
|------|-------|-----|-------|
| idle | `start` / `toggle` | listening | Acquire flock; spawn `pw-record`; start watchers |
| listening | `stop` / `toggle` / silence / max-duration | transcribing | Stop recorder; run STT |
| listening | `force-stop` / `cancel` / `reset` | idle | No paste |
| transcribing | success / empty / hard fail | idle | Paste only on success with text |
| transcribing | `cancel` / `force-stop` / `reset` | idle | Kill local STT client processes for this session |
| any | `clean` | unchanged or idle | Delete WAV; if not recording, ensure idle |

`toggle` while `transcribing`: **no-op** by default (CLI exit 0 with message); DMS should disable click or map to `cancel` via setting later if desired — v1: disable click in QML when `transcribing`.

### Reliability requirements

1. **Exclusive lock** — `flock` on `$STATE_DIR/lock` for mutating commands (`start`, `stop`, `toggle`, recovery). `status` is read-only and must not block long.
2. **Single recorder** — PID file + orphan sweep for `pw-record` whose cmdline contains `$WAV_FILE` (already sketched; keep and harden).
3. **Disown discipline** — recorder must not die with a detached StreamController/DMS parent incorrectly; keep explicit PID tracking.
4. **Watchers during listening** — background helpers (same script process tree or documented child PIDs stored under `STATE_DIR`) for:
   - **Silence**: energy below threshold for `silence_ms` (default **2500**) → `stop`
   - **Max duration**: elapsed ≥ `max_sec` (default **180**) → `stop`
5. **Transcription timeout** — if STT client exceeds timeout, treat as fail → `idle` + error notify (no paste).
6. **Disk guard** — refuse `start` if `DATA_DIR` filesystem has &lt; ~10 MiB free (keep existing check).

### Silence detection

- Implement as a lightweight PCM/energy monitor on the capture path or periodic short reads of the growing WAV.
- Prefer dependency already reasonable on the system (`ffmpeg` or similar available via the dictation-ptt wrapper). Exact tool chosen at implementation time; must not require GPU.
- Configurable: `silence_enabled` (bool), `silence_ms` (int), optional threshold (advanced; default fixed in v1).

### Commands

| Command | Behavior |
|---------|----------|
| `start` | Begin listening if idle |
| `stop` | End listening → transcribe → paste |
| `toggle` | idle↔listening; refuse stacking; no-op in transcribing |
| `status` | Print state; `--json` for DMS (state, elapsed_ms, pids, backend hint) |
| `force-stop` | Kill recorder + session STT clients; idle; no paste |
| `cancel` | Abort transcription or listening without paste |
| `clean` | Remove WAV(s) under `DATA_DIR`; clear stale PID; leave backends alone |
| `reset` | `force-stop` then `clean` |

### Configuration surface

CLI reads (priority high → low):

1. Env vars (`DICTATION_*`)
2. Config file written by DMS, e.g. `$STATE_DIR/config.json` or `$XDG_CONFIG_HOME/dictation-ptt/config.json`
3. Built-in defaults

Keys:

| Key | Default | Meaning |
|-----|---------|---------|
| `mode` | `hold` | `hold` \| `toggle` — documents intended trigger semantics; Deck/niri installers follow this |
| `keyboard_key` | `ScrollLock` | Hint for niri bind generator |
| `silence_enabled` | `true` | Auto-stop on silence |
| `silence_ms` | `2500` | Quiet period before auto-stop |
| `max_duration_enabled` | `true` | Hard cap |
| `max_sec` | `180` | Max listening seconds |

Paste remains `Ctrl+Shift+V` via `wtype` (terminals + most GUI apps).

## DMS plugin design

Location (existing): `desktop/dank-material-shell/plugins/DictationPtt/`  
Deployed via nix-maid to `~/.config/DankMaterialShell/plugins/DictationPtt`.

### Settings panel

- Trigger mode: hold | toggle
- Keyboard key: string / picker defaulting to ScrollLock
- Silence auto-stop: toggle + ms
- Max duration: toggle + seconds

On apply: write CLI config file; regenerate/update niri bind snippet; show toast if niri reload is required.

### Bar widget

- Keep always-on pill + 400 ms status poll (prefer `status --json` when available)
- Click → `toggle`
- While `transcribing`: do not call `toggle`; optionally offer cancel via menu only

### Action menu (context / settings actions)

- Force stop
- Cancel transcription
- Clean cache
- Reset
- Restart STT backends — best-effort `systemctl restart` / `--user` for known units (`parakeet-asr`, `whisper-cpp-asr`, wyoming if present); surface errors in notify if permission denied

## Keyboard (niri)

- Default bind: `ScrollLock`
  - **hold mode**: key down → `dictation-ptt start`; key up → `dictation-ptt stop`
  - **toggle mode**: key down → `dictation-ptt toggle` (ignore key up for action, or only reset if needed)
- DMS owns the desired key string; implementation writes a small managed fragment (nix-maid or generated file under the niri config tree already used by this repo) and documents `niri msg action …` / session reload as needed.
- If a chosen key cannot be expressed in niri binds, DMS shows an error and keeps the previous bind.

## Stream Deck

- Keep versioned fragments under `scripts/ai/dictation-ptt/streamcontroller/`
- When mode is `hold`: Key Down → `start`, Key Up → `stop` (current proven assigner pattern with `registered_down` reset)
- When mode is `toggle`: single RunCommand `toggle` with Key Down→Key Down, Key Up→Key Up
- `install-stt-key.sh` remains the restore path; optional later: generate fragment from CLI config mode

## Error handling

| Failure | User-visible behavior |
|---------|----------------------|
| `/tmp` full | `start` refused + critical notify |
| No mic / `pw-record` dies immediately | idle + error notify |
| All STT backends fail | idle + error; clipboard unchanged |
| Empty transcript | idle; no paste (preserve exit-2 semantics where applicable) |
| `wtype` paste fails | text left on clipboard; warn notify |
| Backend restart denied | notify; no crash of DMS |

## Testing (manual acceptance)

1. Hold ScrollLock: press starts listening, release stops, one paste, no leftover `pw-record` or extra bash
2. Silence ~2.5 s without speech → auto stop + paste path
3. Speak longer than max duration → forced stop
4. Spam Deck / toggle / keyboard: never more than one listening session
5. Induce stuck `transcribing` → Force stop / Reset returns to idle and frees WAV
6. Change key + mode in DMS → new behavior after reload step
7. Clean cache removes large WAV under `DATA_DIR`

## Rollout

1. Harden CLI (lock, watchers, recovery commands, `--json` status) + package rebuild
2. Extend DMS plugin settings + menu; wire config write
3. niri ScrollLock bind + mode-aware semantics
4. Align Stream Deck fragment with mode
5. Update `scripts/ai/dictation-ptt/README.md`

Emergency cleanup today (ops, not blocked on this design): `dictation-ptt reset` once implemented; until then kill stacked bash/`whisper_cpp_transcribe.py`, delete stale WAV, reset state file to `idle`.

## Open decisions resolved in this spec

- Trigger configurability: **C** — hold or toggle in DMS; keyboard default hold
- Silence auto-stop: **yes**, configurable delay in DMS (default 2.5 s)
- Default key: **ScrollLock**, configurable
- Controls: **full** + max duration safety
- Architecture: **CLI engine + DMS settings** (not QS-owned recorder, not a new long-lived daemon)
