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
- `dictation-ptt stop` snapshots `-f` at key-up, SIGKILL after ~0.3s if SIGINT is ignored, and pastes a **stitched** transcript grouped by whisper-stream’s `n_new_line` (`length/step - 1`): keep the last non-junk line of each window, then join windows. Do not treat overlapping wording as a window boundary (that pasted mid-phrase corrections from `-f`, one line per step rewrite). Skip Whisper silence junk (`...`, `[Musique]`, Amara credits). `whisper-stream` has no SIGINT handler that decodes residual PCM — release uses completed steps, not a true end-of-stream flush. `--keep-context` is on so the next window conditions on the previous tokens.
- If the stream dies before stop (model/audio init failure), stop notifies critical (empty silent paste is only for a live stream with no speech).
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

- **Positive**: PCM is decoded while listening; release latency is last-step paste, not a full-clip HTTP upload.
- **Negative**: Streaming quality (small model) can trail batch Parakeet / large-v3-turbo; dual mic open (pw-record + SDL); last in-flight step may be truncated on stop; CUDA whisper-stream often ignores SIGINT so stop SIGKILLs after ~0.3s instead of waiting for a flush. A short hold pastes only the latest window rewrite (up to `--length`). Longer holds join committed windows and can duplicate a seam phrase when Whisper restarts with a similar prefix (`--keep` ms).
- **Constraint**: Stay localhost; do not reintroduce happy-path batch POST for `auto`/`stream` without a superseding ADR.

## References

- [[../../prd/PRD-29-dictation-ptt-quiet-streaming|PRD-29]]
- [[../../plans/PLAN-31-ptt-streaming-stt|PLAN-31]]
- `scripts/ai/dictation-ptt/dictation-ptt.sh`, `dev/ai-stt.nix`
