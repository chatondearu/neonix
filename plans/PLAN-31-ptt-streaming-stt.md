# PLAN-31 — Local streaming STT while PTT is held

- **Status**: done
- **PRD**: [[../prd/PRD-29-dictation-ptt-quiet-streaming|PRD-29]]
- **GitHub**: [#31](https://github.com/chatondearu/neonix/issues/31)
- **Date**: 2026-11-25

## Summary

Today the engine records a WAV, then POSTs the whole file after release (Parakeet OpenAI HTTP, whisper.cpp `/inference`, Wyoming after `AudioStop`). Gradium-style PTT needs PCM consumed **while** the key is held and a flush on release. Stay local; no overlay; paste only at the end.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | Unrelated to STT; do not open STT off localhost |

Do not violate accepted ADRs without superseding them.

#30 is closed (PR #32 merged). This child is unblocked.

## Scope

### In scope

- Feed live PCM into a local streaming ASR from `dictation-ptt start` until `stop`
- On stop: flush remaining audio, take final text, clipboard + existing paste chord
- Package or wire the smallest streaming engine that fits this machine
- Keep Stream Deck / `dictation-ptt-keys` calling the same CLI verbs

### Out of scope

- Cloud STT (Gradium or otherwise)
- Partial-text overlay or live clipboard
- Replacing batch Parakeet/whisper.cpp as general system services (they may remain fallbacks)
- Silence auto-stop as the hold-mode stop path

## Technical approach

Current three backends are **batch**. Wyoming AudioChunk still waits for `AudioStop` before faster-whisper runs. Do **not** fake streaming with overlapping full-file POSTs.

1. Inventory: does any already-installed binary expose true streaming (partials or continuous decode before end-of-utterance)?
2. If none: pick the smallest packagable local streaming ASR that can use this GPU or the existing CPU Parakeet-class path (streaming ONNX, whisper.cpp stream mode, or a streaming Parakeet runtime).
3. Wire `start` to open capture **and** the streaming session in one step; `stop` sends end-of-stream / flush, then pastes.
4. If nothing acceptable packages on this host: **BLOCKED** with the engines tried and why — do not ship a chunked-WAV loop.

Record the engine choice as an ADR if it is a durable stack decision.

## Tasks

- [x] Confirm none of the current batch HTTP/Wyoming paths emit a transcript before end-of-utterance (acceptance: one-line note in the PR / ADR)
- [x] Choose and package a local streaming engine, or stop with BLOCKED (engines evaluated + reason) — **whisper-stream** + `ggml-small` (ADR-006)
- [x] `start` opens capture and the streaming session so PCM is consumed before `stop`
- [x] `stop` flushes, pastes at focus with the existing clipboard + paste chord, returns idle
- [x] Auto / fallback: streaming engine first while listening; batch backends are not the release path
- [x] Tests or a self-check: start then stop without a full-file POST of the whole clip on the happy path
- [x] README: streaming-while-held behavior, no Gradium, no overlay

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| No streaming engine fits Nix/CUDA | BLOCKED; do not fake it |
| Streaming quality worse than batch Parakeet | Prefer an engine with a final flush; keep batch as unused fallback, not the PTT path |

## Test plan

Seams: CLI `start`/`stop` (PCM consumer alive while listening); `stop` paste path; no happy-path notify (after #30).

- [ ] Dictation-ptt tests still pass
- [ ] Happy path does not POST a complete WAV to a batch `/audio/transcriptions` or `/inference` endpoint
- [ ] Empty / error still surfaces via critical notify (from #30 contract)

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra if Nix touched)
- [ ] ADR if a new STT engine is adopted
- [ ] Update foam / README
