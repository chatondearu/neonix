# dictation-ptt

Hold-to-talk local dictation: PipeWire record → STT backend → clipboard paste at focus.

## Triggers

### Stream Deck (hold-to-talk)

1. Create a button on your Stream Deck profile.
2. Add action **press** (or key down): `dictation-ptt start`
3. Add action **release** (or key up): `dictation-ptt stop`
4. Prefer running StreamController from the Nix package (not the old Flatpak) so PATH matches the system.

### DMS bar widget (click toggle)

The **DictationPtt** plugin (`dictationPtt`) shows an always-on mic icon on the Dank Material Shell bar. Click toggles recording (start/stop). States: idle (`mic`), listening (`fiber_manual_record`, red), transcribing (`hourglass_top`, amber). Polls `dictation-ptt status` every 400 ms.

Enable in DMS plugin settings if needed.

## STT backends

| Backend | Port | Service | Role |
|---------|------|---------|------|
| **Parakeet** TDT 0.6B v3 (ONNX, CPU) | `10310` | `parakeet-asr` | Default — fastest for short FR clips |
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
