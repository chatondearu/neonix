# dictation-ptt

Local dictation (hold or toggle): PipeWire record → STT backend → clipboard paste at focus (`Ctrl+Shift+V` via `wtype`).

WAV captures go under `/tmp/dictation-ptt-$UID/` (not the small `XDG_RUNTIME_DIR` tmpfs) so long sessions cannot fill the session runtime.

## Configuration

Settings live in `~/.config/dictation-ptt/config.json` (override path with `DICTATION_CONFIG`). DMS **Dictation PTT** settings write this file and regenerate the niri bind fragment on save.

| Key | Default | Description |
|-----|---------|-------------|
| `mode` | `hold` | `hold` or `toggle` — affects keyboard bind and recommended Stream Deck fragment |
| `keyboard_key` | `ScrollLock` | niri XKB key name (sync normalizes `ScrollLock` → `Scroll_Lock`) |
| `silence_enabled` | `true` | Auto-stop after quiet period while listening |
| `silence_ms` | `2500` | Quiet period (ms) before silence auto-stop |
| `max_duration_enabled` | `true` | Hard cap on listening length |
| `max_sec` | `180` | Max listening duration (seconds) |

Example:

```json
{
  "mode": "hold",
  "keyboard_key": "ScrollLock",
  "silence_enabled": true,
  "silence_ms": 2500,
  "max_duration_enabled": true,
  "max_sec": 180
}
```

Write from CLI (also syncs niri):

```bash
./scripts/ai/dictation-ptt/write-cli-config.sh hold ScrollLock true 2500 true 180
```

## Silence and max duration

While **listening**, background watchers (when enabled in config) can stop recording without a manual trigger:

| Watcher | Config | Behavior |
|---------|--------|----------|
| Silence | `silence_enabled`, `silence_ms` | Stops after `silence_ms` ms without speech (default 2.5 s) |
| Max duration | `max_duration_enabled`, `max_sec` | Forced stop after `max_sec` seconds (default 180 s) |

These are especially important in **hold** mode on the **keyboard**: niri cannot bind key release (see below), so silence and max duration are the primary keyboard stop paths besides DMS / CLI / Stream Deck.

Disable silence for manual-only stop: set `"silence_enabled": false` in config (or turn off in DMS settings).

## Triggers

### Stream Deck (mode-aware)

Versioned fragments under `scripts/ai/dictation-ptt/streamcontroller/`:

| Mode | Fragment | Behavior |
|------|----------|----------|
| `hold` | `stt-key.json` | Key Down → `start`, Key Up → `stop` (true press+release hold) |
| `toggle` | `stt-key-toggle.json` | Key Down → `toggle` (single RunCommand) |

**Hold assigner pattern:** `RunCommand` only *runs* on its “Key Down” assigner, but tracks a `registered_down` flag that must be cleared by a “Key Up” assigner — otherwise the action fires only once.

| Action | Physical Key Down | Physical Key Up |
|--------|-------------------|-----------------|
| Start | → Key Down (run start) | → Key Up (reset flag) |
| Stop | → Key Up (reset flag) | → Key Down (run stop) |

Install or restore the key at **1x0** (label **STT**) from config mode (or override):

```bash
./scripts/ai/dictation-ptt/streamcontroller/install-stt-key.sh
# explicit:
./scripts/ai/dictation-ptt/streamcontroller/install-stt-key.sh --mode hold
./scripts/ai/dictation-ptt/streamcontroller/install-stt-key.sh --mode toggle
# then restart StreamController
```

After editing `~/.var/app/com.core447.StreamController/data/pages/default.json` by hand, restart StreamController. Prefer the **Nix** StreamController binary (not Flatpak) so PATH sees `dictation-ptt`.

Also versioned: `default-page.snapshot.json` (hold layout reference), `install-stt-key.sh`.

### DMS bar widget (click toggle)

The **DictationPtt** plugin (`dictationPtt`) shows an always-on mic icon on the Dank Material Shell bar. Click toggles recording (start/stop). States: idle (`mic`), listening (`fiber_manual_record`, red), transcribing (`hourglass_top`, amber). Polls `dictation-ptt status` every 400 ms.

**DMS settings** (plugin settings panel):

- **Trigger mode** — `hold` or `toggle` (see semantics below; keyboard vs Stream Deck differ in hold mode)
- **Keyboard key** — niri XKB name; synced to `~/.config/niri/dms/dictation-ptt.kdl`
- **Silence auto-stop** / **Silence timeout (ms)**
- **Max duration** / **Max duration (seconds)**
- **Recovery** buttons: Force stop, Cancel, Clean, Reset, Restart backends
- **Write config now** — force persist + niri sync

Opening **Dictation PTT** settings bootstraps `~/.config/dictation-ptt/config.json` and regenerates the niri bind file.

### Keyboard (niri Scroll_Lock)

`desktop/niri/config.kdl` optionally includes `dms/dictation-ptt.kdl` (separate from DMS-owned `dms/binds.kdl` so regenerations do not wipe dictation binds). Saving DMS settings (or running the sync script) writes:

`~/.config/niri/dms/dictation-ptt.kdl`

| `config.json` `mode` | Bind behavior |
|----------------------|---------------|
| `hold` (default) | **Press** → `dictation-ptt start` only |
| `toggle` | **Press** → `dictation-ptt toggle` |

**niri key-release binds are not supported** on niri 25.x/26.04 (PR [niri-wm/niri#3621](https://github.com/niri-wm/niri/pull/3621) still open; `Key+Release` / `Scroll_Lock+Release` fails `niri validate`). In **hold** mode the keyboard therefore cannot stop on key-up. Stop via:

- silence auto-stop (`silence_enabled` / `silence_ms`, default 2500 ms), and/or
- max duration (`max_duration_enabled` / `max_sec`, default 180 s), and/or
- DMS widget click / recovery buttons / CLI / Stream Deck Key Up

True press+release hold remains available on the **Stream Deck** path above.

Default key in settings is `ScrollLock`; the sync script maps it to the XKB name **`Scroll_Lock`** (required by niri). Other keys must use valid XKB names (see `wev`).

Regenerate / reload:

```bash
# After editing ~/.config/dictation-ptt/config.json by hand:
./scripts/ai/dictation-ptt/sync-niri-bind.sh
# Prefer explicit reload (also attempted by the script):
niri msg action load-config-file
```

Validate the generated fragment:

```bash
niri validate -c ~/.config/niri/dms/dictation-ptt.kdl
```

## Recovery commands

Use when dictation is stuck (`listening` / `transcribing`), WAV cache is large, or orphaned processes remain.

| Command | Effect |
|---------|--------|
| `dictation-ptt force-stop` | Kill recording, watchers, in-flight transcribe; set state `idle` |
| `dictation-ptt cancel` | Alias of `force-stop` |
| `dictation-ptt clean` | Remove WAV files under data dir; clear pid files |
| `dictation-ptt reset` | `force-stop` + `clean` + ensure `idle` |

Same commands are exposed as buttons in DMS **Dictation PTT** settings. **Restart backends** restarts `parakeet-asr` and `whisper-cpp-asr` (system or user units, best-effort).

Quick recovery when idle is wrong or RAM is climbing:

```bash
dictation-ptt status
dictation-ptt status --json
dictation-ptt reset
```

## Troubleshooting stuck state / RAM

Symptoms: bar icon stuck on listening/transcribing, repeated notifications, growing RAM, or large files under `/tmp/dictation-ptt-$UID/`.

1. Check state: `dictation-ptt status --json` (fields: `state`, `elapsed_ms`, `record_pid`, `wav_bytes`, `mode`).
2. **Reset**: `dictation-ptt reset` (preferred one-shot fix).
3. If processes remain: `dictation-ptt force-stop`, then inspect `pgrep -af 'pw-record|whisper_cpp_transcribe|openai_transcribe|wyoming_transcribe'`.
4. **Clean cache**: `dictation-ptt clean` or remove stale WAV under `/tmp/dictation-ptt-$UID/` (default `DICTATION_DATA_DIR`).
5. Reinstall Stream Deck key if hold/toggle behavior mismatches config: `install-stt-key.sh [--mode hold|toggle]`.
6. After config or niri changes: `sync-niri-bind.sh` and `niri msg action load-config-file`.
7. STT backend issues: restart units (`systemctl restart parakeet-asr whisper-cpp-asr`) or use DMS **Restart backends**.

State and lock files: `$XDG_RUNTIME_DIR/dictation-ptt/` (runtime). Audio cache: `/tmp/dictation-ptt-$UID/` by design — avoids filling the small session tmpfs.

## STT backends

| Backend | Port | Service | Role |
|---------|------|---------|------|
| **Parakeet** TDT 0.6B v3 (ONNX, CPU) | `10310` | `parakeet-asr` | Default — fastest for short FR clips (`-long-audio` for longer takes) |
| **whisper.cpp** large-v3-turbo (CUDA) | `10311` | `whisper-cpp-asr` | Fallback / quality |
| **Wyoming** faster-whisper | `10300` | `wyoming-faster-whisper-english` | Legacy fallback |

All listeners are localhost-only (`127.0.0.1` or restricted via `IPAddressAllow`); no firewall ports opened.

### Backend selection

`DICTATION_STT` controls routing (default: `auto`):

| Value | Behavior |
|-------|----------|
| `auto` | Parakeet → whisper.cpp → Wyoming (first healthy backend) |
| `parakeet` | Force Parakeet OpenAI HTTP (`http://127.0.0.1:10310/v1`) |
| `whisper` | Force whisper.cpp OpenAI HTTP (`http://127.0.0.1:10311`) |
| `wyoming` | Force Wyoming TCP (`tcp://127.0.0.1:10300`) |

Override URLs if needed: `DICTATION_PARAKEET_URL`, `DICTATION_WHISPER_URL`, `DICTATION_WYOMING_URI`.

## Latency expectations

Target: **≤ 3 s** end-to-end (release → paste) for a ~3 s utterance on Parakeet.

| Backend | ~3 s clip (typical) | Notes |
|---------|-------------------|-------|
| Parakeet (CPU ONNX) | ~1 s | Default; scales with clip length |
| whisper.cpp (CUDA) | ~0.2–2 s | Depends on GPU load and model |
| Wyoming (CPU float32) | ~15–30 s | Legacy fallback only |

Measured on this machine (2026-08-03): Parakeet ~1.0 s, whisper.cpp ~0.2 s for a 2 s clip.

## Notifications

Desktop notifications (title **Dictation**, replace-id to avoid stacking):

| Event | Body | Urgency |
|-------|------|---------|
| Start | Écoute… | low |
| Transcribing | Transcription… | low |
| Error | mic / STT / paste failure | critical |

Empty transcripts do not notify and do not paste.

## Parakeet model attribution

The Parakeet TDT 0.6B v3 ONNX models used by `parakeet-asr` are derived from NVIDIA Parakeet speech recognition models, licensed under **[CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/)**. When distributing or documenting this setup, attribute NVIDIA as the original model author. Community ONNX conversion: [istupakov/parakeet-tdt-0.6b-v3-onnx](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx). Server binary: [achetronic/parakeet](https://github.com/achetronic/parakeet).

## CLI

```bash
dictation-ptt start         # begin recording
dictation-ptt stop          # stop, transcribe, paste
dictation-ptt toggle        # start or stop (DMS widget / toggle mode)
dictation-ptt status        # idle | listening | transcribing
dictation-ptt status --json # machine-readable status
dictation-ptt force-stop    # kill session, return idle
dictation-ptt cancel        # alias force-stop
dictation-ptt clean         # remove WAV cache
dictation-ptt reset         # force-stop + clean
```

## Manual test

```bash
dictation-ptt start
# speak
dictation-ptt stop
```

Force a backend:

```bash
DICTATION_STT=parakeet dictation-ptt start
sleep 3
time DICTATION_STT=parakeet dictation-ptt stop
```

Automated checks (from repo):

```bash
bash scripts/ai/dictation-ptt/test_recovery.sh
bash scripts/ai/dictation-ptt/test_watchers.sh
bash scripts/ai/dictation-ptt/test_dictation_state.sh
```

## Failures

Desktop notifications titled **Dictation** appear for mic/PipeWire issues, missing paste tools (`wl-copy`, `wtype`), and STT/model errors.
