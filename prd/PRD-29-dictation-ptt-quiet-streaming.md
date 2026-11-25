# PRD-29 — Quiet PTT notifications and local streaming STT

- **Status**: approved
- **GitHub**: [#29](https://github.com/chatondearu/neonix/issues/29)
- **Date**: 2026-11-25
- **Tags**: #product #stt

## Problem

Dictation PTT on neo-nix is batch: hold records a WAV, release POSTs the whole file, then paste. Desktop toasts ("Écoute…", "Transcription…") fire on the happy path via D-Bus and feel invasive; they also sit on the start/stop path. The user wants Gradium-like behavior: listen the instant the key goes down, decode while speaking, flush on release — without a live overlay, and without a cloud API.

## Goals

- [ ] Happy-path PTT emits no desktop notifications; errors still notify
- [ ] Capture starts immediately on push (no notify-send before the recorder)
- [ ] A local streaming ASR consumes PCM while the key is held
- [ ] Release only flushes remaining audio and pastes at focus
- [ ] Stream Deck and keyboard daemon keep using start / stop / toggle

## Non-goals

- Gradium (or any) cloud STT API
- Live overlay, widget transcript, or live clipboard of partial text
- Hold-vs-toggle / Moonlander key mapping (separate thread)
- Replacing Parakeet / whisper.cpp as general system STT services
- Changing the paste chord (`Ctrl+Shift+V`)

## Users & scenarios

| Persona | Scenario |
| ------- | -------- |
| Workstation owner | Holds Stream Deck STT or keyboard PTT, speaks, releases; text appears at focus without toasts |
| Workstation owner | Mic or backend fails; one critical notification explains the error |
| Workstation owner | Watches the DMS mic widget for idle / listening / transcribing |

## Requirements

### Functional

- [ ] Start / stop / toggle success path does not call `notify-send` (or equivalent desktop toast)
- [ ] Failures (mic, empty capture, missing paste tools, STT error) still notify at critical urgency
- [ ] DMS DictationPtt widget remains the status surface
- [ ] While listening, a local streaming engine is already consuming PCM (not waiting for key-up)
- [ ] On stop, paste uses the flushed streaming result; it must not wait for a full-file HTTP POST of the entire clip
- [ ] Triggers stay the existing CLI (`start` / `stop` / `toggle`)

### Non-functional

- [ ] Stay on-machine (localhost STT only)
- [ ] Child 1 (notifications) ships even if child 2’s engine choice slips
- [ ] If no acceptable local streaming engine can be packaged, child 2 is BLOCKED — do not fake streaming with chunked full-file POSTs
- [ ] One child = one PR; Conventional Commits; English artifacts
- [ ] Format Nix with alejandra when touching `.nix`

## Related project memory

- ADRs: none on STT streaming. [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] is llama-swap LAN auth only (do not treat it as an STT constraint).
- Existing stack: `dictation-ptt` CLI, `dictation-ptt-keys`, Stream Deck fragments, Parakeet / whisper.cpp / Wyoming (all batch today).

## Open questions

1. Which local streaming engine to package (child 2 plan picks; candidates: streaming ONNX / whisper.cpp stream / streaming Parakeet runtime). If none fit this GPU/CPU, BLOCKED.

## Success metrics

- Happy path: zero desktop notifications for a complete start→speak→stop→paste
- Errors still produce a Dictation toast
- Observable: while held, the streaming process is reading PCM
- Time from key-up to paste does not include a full-utterance file upload to a batch HTTP endpoint

## Implementation pointer

- [[../plans/PLAN-30-ptt-errors-only-notifs|PLAN-30]] — notifications
- [[../plans/PLAN-31-ptt-streaming-stt|PLAN-31]] — streaming STT
