# ADR-006 — PTT streaming STT via whisper-stream

- **Status**: accepted
- **Date**: 2026-11-25
- **Tags**: #stt #ai #dictation
- **GitHub**: [#31](https://github.com/chatondearu/neonix/issues/31) (child of [#29](https://github.com/chatondearu/neonix/issues/29))

## Context

Dictation PTT recorded a WAV then POSTed the whole file after key-up (Parakeet OpenAI HTTP, whisper.cpp `/inference`, Wyoming after `AudioStop`). None of those paths emit a transcript before end-of-utterance. PRD-29 / PLAN-31 require a **local** streaming ASR that consumes PCM while the key is held, flush on release, no cloud, no overlay. Fake chunked full-file POSTs are forbidden.

## Decision

Use **whisper.cpp `whisper-stream`** (already on neo-nix via `pkgs.whisper-cpp` + CUDA) with a dedicated **`ggml-small`** multilingual model under `/hdd/whisper/ggml-small.bin` (downloaded by `whisper-cpp-models.service`).

- `dictation-ptt start` opens PipeWire capture **and** starts `whisper-stream` (SDL capture + step decode).
- `dictation-ptt stop` SIGINT-flushes the stream process, pastes final text with the existing clipboard + `Ctrl+Shift+V` chord.
- `DICTATION_STT=auto|stream` (default `auto`) uses this path only — batch backends are not the release path.
- Explicit `parakeet` / `whisper` / `wyoming` remain available for debugging legacy batch.

## Alternatives considered

| Alternative | Why rejected |
| ----------- | ------------ |
| Chunked / overlapping full-file POSTs to Parakeet or whisper-server | Forbidden by PLAN-31 (fake streaming) |
| Wyoming AudioChunk while held | faster-whisper still decodes only after `AudioStop` |
| sherpa-onnx online (+ new models) | Packagable, but heavier than wiring an already-installed binary |
| whisper-stream with `ggml-large-v3-turbo` | Slow load / VRAM fight with `whisper-cpp-asr`; small model is enough for PTT flush quality |
| Cloud / Gradium | Out of scope (PRD-29) |

## Consequences

- **Positive**: PCM is decoded while listening; release latency is flush + paste, not a full-clip HTTP upload.
- **Negative**: Streaming quality (small model) can trail batch Parakeet / large-v3-turbo; dual mic open (pw-record + SDL) on PipeWire.
- **Constraint**: Stay localhost; do not reintroduce happy-path batch POST for `auto`/`stream` without a superseding ADR.

## References

- [[../../prd/PRD-29-dictation-ptt-quiet-streaming|PRD-29]]
- [[../../plans/PLAN-31-ptt-streaming-stt|PLAN-31]]
- `scripts/ai/dictation-ptt/dictation-ptt.sh`, `dev/ai-stt.nix`
