# dictation-ptt

Local push-to-talk dictation on neo-nix.

## Behavior

- **Start** (`dictation-ptt start`): PipeWire WAV capture for watchers + **whisper-stream** session so PCM is decoded while the key is held.
- **Stop** (`dictation-ptt stop`): stop the stream process, paste the last decoded `-f` line at focus (`wl-copy` + `Ctrl+Shift+V` via `wtype`). No residual-PCM flush on SIGINT. Stream death before stop → critical notify. No live overlay; no cloud STT.
- **Happy path**: no desktop notifications (DMS DictationPtt widget is the status surface). Errors still notify at critical urgency.

## Configuration

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `DICTATION_STT` | `auto` | `auto`/`stream` = streaming PTT; `parakeet`/`whisper`/`wyoming` = legacy batch after release |
| `DICTATION_STREAM_MODEL` | `/hdd/whisper/ggml-small.bin` | ggml model for `whisper-stream` |
| `DICTATION_STREAM_BIN` | `whisper-stream` | Streaming binary |
| `DICTATION_STREAM_CAPTURE` | (unset) | Optional SDL capture device id |
| `DICTATION_STREAM_NO_GPU` | (unset) | Set `1` to force CPU decode |

Operator details: `scripts/ai/dictation-ptt/README.md`. Decision: [[foam/decisions/ADR-006-ptt-streaming-whisper-stream|ADR-006]].
