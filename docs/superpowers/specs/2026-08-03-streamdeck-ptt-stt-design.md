# Design: Stream Deck hold-to-talk STT (Wyoming)

Date: 2026-08-03  
Status: approved for planning  
Scope: Phase 0 (stack hygiene) then Phase 1 (Approach A dictation)

## Goal

Press-and-hold a Stream Deck button to record from the microphone; on release, transcribe locally and paste text into the focused Wayland window (Niri).

## Non-goals (later)

- Wake word “ordinateur” + full machine control agent
- Approach B (llama-swap `/v1/audio/transcriptions`) or Approach C (whisrs / OpenDictate)
- Changing Piper voice language
- Cleaning leftover Flatpak StreamController data

Future wake-word control can reuse the same Wyoming STT path and the existing `openWakeWord` service; only the trigger changes (wake word instead of Stream Deck).

## Current baseline

- `llama-swap` on `:9292` (pinned v224 at design time; update in Phase 0)
- `wyoming.faster-whisper` server `english` on TCP `:10300` (CPU, `language = auto`)
- `wyoming.piper` + `openWakeWord` enabled, bound to `0.0.0.0`
- `streamcontroller` installed; `wtype` + `wl-clipboard` already on PATH via DMS shell config
- GPU: RTX 3090 24 GiB; `nixpkgs.config.cudaSupport = true`

## Phase 0 — Black-spot fixes

### 0.1 Memory limits on the real Whisper unit

Replace the dead override `systemd.services.wyoming-faster-whisper-main` with `wyoming-faster-whisper-english`, keeping:

- `Restart = "on-failure"`
- `RestartSec = 10`
- `MemoryMax = "16G"`
- `MemoryHigh = "14G"`

### 0.2 Whisper language and device

In `services.wyoming.faster-whisper.servers.english` (rename of the Nix attribute is optional; unit name stays `english` unless renamed carefully):

- `device = "cuda"`
- `language = "fr"`
- `initialPrompt` (or module equivalent) biased to technical FR/EN dictation, e.g. mentioning API, commit, TypeScript, NixOS

If CUDA fails at runtime (`ctranslate2` without CUDA), fall back to documenting the failure and reverting `device = "cpu"` rather than blocking Phase 1.

### 0.3 Localhost-only Wyoming listeners

Set URIs to loopback:

- Whisper: `tcp://127.0.0.1:10300`
- Piper: `tcp://127.0.0.1:10200`
- openWakeWord: `tcp://127.0.0.1:10400`

### 0.4 Firewall

Remove from `dev/ai.nix` `allowedTCPPorts`: `10400`, `10200`, `10300`, `10301`.

Do **not** remove VR UDP `10400` in `gaming/vr/vr.nix` (unrelated).

Leave `9292` (llama-swap) as currently configured unless a separate hardening pass is requested.

### 0.5 llama-swap update

Run `pkgs/llama-swap/update.sh` (or equivalent custom-package update) to move from v224 to latest (v246 at design time). Rebuild/switch as usual.

### 0.6 Deferred

- Piper `en-us-ryan-high` — leave as-is
- `~/.var/app/com.core447.StreamController` Flatpak remnant — leave as-is
- VRAM contention LLM vs Whisper — accept share on 24 GiB; revisit only if OOM

## Phase 1 — Approach A: hold-to-talk dictation

### Interaction model

- **Press** Stream Deck button → start recording
- **Hold** → keep recording
- **Release** → stop, transcribe, paste into focused window

No toggle mode.

### Components

1. **CLI** `dictation-ptt` (name may match packaging), with subcommands:
   - `start` — begin capture from default/input mic to a temp WAV (or raw PCM) under `/tmp` or `$XDG_RUNTIME_DIR`
   - `stop` — end capture, send audio to Wyoming Whisper at `127.0.0.1:10300`, copy transcript to clipboard, paste via `wtype` (Ctrl+v) or type if paste is unreliable for the focused app
2. **StreamController** button actions:
   - Key down / press → `dictation-ptt start`
   - Key up / release → `dictation-ptt stop`
3. **Audio capture** — PipeWire (`pw-record` or `ffmpeg` with PipeWire), mono 16 kHz preferred for Whisper
4. **Wyoming client** — small Python (or existing CLI) speaking Wyoming protocol to the local faster-whisper server

### Data flow

```text
Stream Deck hold
  → StreamController press  → dictation-ptt start → pw-record → $RUNTIME/dictation.wav
  → StreamController release → dictation-ptt stop
       → Wyoming STT (fr, cuda)
       → wl-copy
       → wtype paste into focused client
```

### Error handling

- `start` while already recording: no-op or restart cleanly (pick: **restart** recording)
- `stop` with no active recording: exit 0, no paste
- Empty / silence transcript: do not paste
- Whisper unreachable: notify (stderr + optional desktop notification), exit non-zero, no paste
- Missing mic / PipeWire failure: same as above

### Packaging / NixOS

- Ship the script (and any tiny client helper) via the NixOS config (`environment.systemPackages` or `pkgs` wrapper) so StreamController can call a stable PATH binary
- Do not require Home Assistant
- Keep Wyoming as the STT backend (Approach A)

### Manual test plan

1. After Phase 0 switch: `systemctl status wyoming-faster-whisper-english` shows CUDA path (no float32 CPU warning); MemoryMax applied; listeners on `127.0.0.1` only
2. Hold Stream Deck button, speak French with English tech terms, release → text appears in focused editor/terminal
3. Confirm no paste on silence / failed STT
4. Confirm llama-swap still serves `/v1/models` after update

## Architecture fit for later “ordinateur”

Phase 1 leaves a clear seam: **trigger** (Stream Deck) vs **pipeline** (record → STT → act). A future wake-word daemon can call the same STT (and later an agent) without replacing Whisper. openWakeWord on `:10400` stays available for that work.

## Success criteria

- Phase 0: black spots listed above fixed; Whisper usable on localhost with FR bias and CUDA when possible
- Phase 1: hold-to-talk dictation works end-to-end from Stream Deck into the focused window without cloud services
