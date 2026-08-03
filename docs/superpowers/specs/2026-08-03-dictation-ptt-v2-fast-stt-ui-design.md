# Design: dictation-ptt v2 — fast STT backends + always-on UI

Date: 2026-08-03  
Status: approved for planning  
Supersedes (partially): UX silence and CPU latency issues from Phase 1 of `2026-08-03-streamdeck-ptt-stt-design.md`  
Keeps: `dictation-ptt` script as the iterable core (not Voxtype / OmniVoice as primary)

## Goal

Keep the local `dictation-ptt` hold-to-talk pipeline, but make it:

1. **Fast** — ~1–3 s transcription for short utterances (scales with recording length)
2. **Visible** — always-on status indicator + notifications on start / stop / transcribe / errors
3. **Swappable** — multiple local STT backends behind one client interface, including **Parakeet** and **whisper.cpp CUDA**
4. **Future-proof** — same STT HTTP surface reusable later for wake-word “ordinateur” + agent (out of scope now)

## Non-goals

- Replacing the CLI with Voxtype / OmniVoice / whisrs as the primary UX
- Wake word + full machine control agent
- Voice cloning / dubbing (OmniVoice) — optional later, separate track
- Fixing Piper English voice
- Making Wyoming faster-whisper CUDA via ctranslate2 overlay (known broken in current nixpkgs; keep as optional fallback only)

## Current pain (Phase 1)

- Success path is silent → feels broken
- Wyoming `large-v3-turbo` on **CPU float32** → ~15–30 s for short clips
- No always-visible status in DMS

## Architecture

```text
                    ┌─────────────────────────┐
  Stream Deck ─────►│                         │
  DMS widget  ─────►│  dictation-ptt          │──► wl-copy + wtype
  (manual click)    │  start | stop | status  │
                    └───────────┬─────────────┘
                                │ POST multipart WAV
                                ▼
              ┌─────────────────────────────────────┐
              │  STT router (OpenAI-compatible)     │
              │  POST /v1/audio/transcriptions      │
              └───────────┬─────────────┬───────────┘
                          │             │
              ┌───────────▼──┐   ┌──────▼──────────────┐
              │ Parakeet     │   │ whisper.cpp server  │
              │ TDT 0.6B v3  │   │ (CUDA, large-v3-    │
              │ OpenAI HTTP  │   │  turbo or small)    │
              │ :10310       │   │ :10311              │
              └──────────────┘   └─────────────────────┘
                          │
              optional fallback: Wyoming :10300 (current)
```

**Why OpenAI `/v1/audio/transcriptions`:** one client code path; Parakeet community servers and llama.cpp/whisper.cpp already speak this; later llama-swap or an agent can call the same URL.

## Backend choices

### A — Parakeet TDT 0.6B v3 (default for speed)

- **Why:** among the fastest open ASR stacks in 2026; strong EU language coverage including French; good enough for FR + English tech terms for dictation
- **How to run locally (preferred packaging order to evaluate in plan):**
  1. Lightweight **OpenAI-compatible server** (Go/Rust/ONNX preferred over heavy NeMo Python), e.g. community `parakeet` / `parakeet-server` style wrapping ONNX INT8 or CUDA EP
  2. Systemd user/system unit on `127.0.0.1:10310`
  3. Models under `/hdd/huggingface` or a dedicated `/hdd/parakeet` cache
- **License note:** NVIDIA Parakeet is typically **CC-BY-4.0** (attribution) — document in README
- **Default backend** for `dictation-ptt` once the service is healthy

### B — whisper.cpp CUDA (quality / multilingual fallback)

- **Why:** battle-tested, fits existing llama.cpp/CUDA culture on this machine; excellent FR + code-switching; predictable Nix packaging story vs broken ctranslate2 CUDA
- **How:** `whisper-server` (or equivalent) with CUDA, model `large-v3-turbo` or `small` for latency trade-off, listen `127.0.0.1:10311`
- **Use when:** Parakeet unavailable, or user forces `DICTATION_STT=whisper` for harder audio / more languages

### C — Wyoming faster-whisper (legacy fallback)

- Keep the existing service for now
- Not the default for dictation after v2
- May be disabled later once A/B prove stable

### Selection

Env / config (exact names in plan):

- `DICTATION_STT=parakeet|whisper|wyoming` (default `parakeet` when service up, else fall through)
- Or a small file under `$XDG_CONFIG_HOME/dictation-ptt/config`

## UI / feedback

### Notifications (`notify-send`, title `Dictation`)

| Event | Body (FR OK) | Urgency |
|-------|----------------|---------|
| start | Écoute… | low/normal |
| stop → transcribe begin | Transcription… | normal |
| success | optional short “Collé” or none (prefer **none** to reduce noise; keep start + transcribe) | — |
| error | mic / STT / paste failure | critical |

Use a stable replace ID so “Écoute…” is replaced by “Transcription…” instead of stacking.

### Always-visible indicator

- **Preferred:** DMS / Quickshell widget always on the bar (idle / listening / transcribing), click toggles start/stop
- **Fallback if DMS plugin cost is high:** StatusNotifierItem tray icon always visible (same three states + click)
- No show/hide flicker: icon/widget **always mounted**; only the **state/color** changes

States:

1. `idle` — ready
2. `listening` — recording
3. `transcribing` — after release, waiting for STT

## CLI / triggers (unchanged contract, extended)

- `dictation-ptt start|stop` — Stream Deck press/release
- `dictation-ptt toggle` — for widget click (optional but recommended)
- `dictation-ptt status` — prints `idle|listening|transcribing` for the widget poller
- State dir remains under `$XDG_RUNTIME_DIR/dictation-ptt/`

## Integration with existing stack

| Component | Role in v2 |
|-----------|------------|
| `dictation-ptt` | Orchestrator (record, route STT, paste, notify, status file) |
| Parakeet unit `:10310` | Default fast STT |
| whisper.cpp unit `:10311` | Fallback / quality |
| Wyoming `:10300` | Legacy fallback |
| llama-swap `:9292` | Unchanged for LLMs; later may proxy STT or share `/v1/audio/transcriptions` — not required for v2 |
| openWakeWord / Piper | Untouched; future “ordinateur” reuses STT HTTP |
| StreamController | Same press/release bindings |
| DMS | Always-on widget (or tray fallback) |

## Performance targets

- Short utterance (~2–5 s audio): **≤ 3 s** wall time from release to paste when Parakeet or CUDA whisper is healthy
- Longer recordings: roughly linear; no hard cap, but UI must show `transcribing`
- If STT exceeds a timeout (e.g. 60 s): notify error, no paste

## Security / binding

- New STT servers bind **127.0.0.1** only
- Do not open new firewall ports

## Phased delivery

### Phase 2a — Feedback without backend swap

- Notifications start / transcribe / errors (replace-id)
- Always-on status (DMS widget or SNI) + `status`/`toggle`
- Still on Wyoming (slow) but UX no longer silent

### Phase 2b — Parakeet service + client switch

- Package/run Parakeet OpenAI-compatible server
- Point `dictation-ptt` at it by default
- Benchmark short clip latency; keep Wyoming fallback

### Phase 2c — whisper.cpp CUDA second backend

- Add whisper.cpp CUDA server
- `DICTATION_STT` switch + auto-fallback order: parakeet → whisper → wyoming

### Phase 2d — DMS polish (if 2a used tray)

- Native DMS widget if tray was temporary

## Success criteria

- Hold-to-talk still works from Stream Deck
- Always-visible idle/listening/transcribing indicator; no tray flicker
- Notifications on start and when transcription begins; critical on errors
- Default path uses Parakeet; whisper.cpp CUDA available; short-clip latency typically ≤ 3 s on healthy GPU/ONNX path
- `dictation-ptt` remains the single orchestration entrypoint for later agent work

## Open implementation choices (resolve in plan, not blockers)

1. Exact Parakeet server package (Go ONNX vs Rust vs Python NeMo) — prefer **non-NeMo**, OpenAI-compatible, CUDA or fast ONNX
2. DMS plugin vs SNI first — prefer DMS if a minimal plugin is realistic in one iteration; else SNI in 2a
3. Whether whisper.cpp is standalone `whisper-server` or exposed via llama-swap — prefer **standalone** for isolation from LLM VRAM thrash
