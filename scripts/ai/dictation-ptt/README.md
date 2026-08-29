# dictation-ptt

Local dictation (hold or toggle): PipeWire record → STT backend → clipboard paste at focus (`Ctrl+Shift+V` via `wtype`).

WAV captures go under `/tmp/dictation-ptt-$UID/` (not the small `XDG_RUNTIME_DIR` tmpfs) so long sessions cannot fill the session runtime.

## Triggers

### Stream Deck (hold-to-talk)

StreamController page `default.json` key **1x0** (label **STT**) is configured for hold-to-talk:

| Physical event | Action | Command |
|----------------|--------|---------|
| Key Down (press) | RunCommand | `/run/current-system/sw/bin/dictation-ptt start` |
| Key Up (release) | RunCommand | `/run/current-system/sw/bin/dictation-ptt stop` |

**Important:** `RunCommand` only *runs* the command on its “Key Down” assigner, but it also tracks a `registered_down` flag that must be cleared by a “Key Up” assigner — otherwise the action fires only once.

| Action | Physical Key Down | Physical Key Up |
|--------|-------------------|-----------------|
| Start | → Key Down (run start) | → Key Up (reset flag) |
| Stop | → Key Up (reset flag) | → Key Down (run stop) |

If you recreate the button in the UI:

1. Open StreamController → page **default** → key for STT.
2. Add **OS Plugin → Run Command** → `dictation-ptt start`. Event Assigner: Key Down→Key Down, Key Up→Key Up.
3. Add a **second** Run Command → `dictation-ptt stop`. Event Assigner: Key Down→Key Up, Key Up→Key Down.
4. Labels: e.g. top text `STT`. Detached = on.
5. Prefer the **Nix** StreamController binary (not Flatpak) so PATH sees `dictation-ptt`.

After editing `~/.var/app/com.core447.StreamController/data/pages/default.json` by hand, restart StreamController.

Or restore from the repo fragment:

```bash
./scripts/ai/dictation-ptt/streamcontroller/install-stt-key.sh
# then restart StreamController
```

Versioned under `scripts/ai/dictation-ptt/streamcontroller/`: `stt-key.json`, `default-page.snapshot.json`, `install-stt-key.sh`.

### DMS bar widget (click toggle)

The **DictationPtt** plugin (`dictationPtt`) shows an always-on mic icon on the Dank Material Shell bar. Click toggles recording (start/stop). States: idle (`mic`), listening (`fiber_manual_record`, red), transcribing (`hourglass_top`, amber). Polls `dictation-ptt status` every 400 ms.

Enable in DMS plugin settings if needed.

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
dictation-ptt start    # begin recording
dictation-ptt stop     # stop, transcribe, paste
dictation-ptt toggle   # start or stop (DMS widget)
dictation-ptt status   # idle | listening | transcribing
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

## Failures

Desktop notifications titled **Dictation** appear for mic/PipeWire issues, missing paste tools (`wl-copy`, `wtype`), and STT/model errors.
