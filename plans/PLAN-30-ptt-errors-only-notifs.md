# PLAN-30 — Drop happy-path dictation notifications

- **Status**: in-progress
- **PRD**: [[../prd/PRD-29-dictation-ptt-quiet-streaming|PRD-29]]
- **GitHub**: [#30](https://github.com/chatondearu/neonix/issues/30)
- **Date**: 2026-11-25

## Summary

Happy-path dictation PTT currently toasts "Écoute…", "Transcription…", and recovery info via D-Bus. Those toasts are invasive and can delay start/stop. Keep critical error notifications only; the DMS widget remains the status UI.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| _(none on notifications)_ | — |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Happy-path start / stop / toggle / recovery: no desktop notification
- Error paths: still notify (critical)
- Tests and README that describe notification behavior

### Out of scope

- Streaming STT (#31)
- Changing hold/toggle mode or keyboard key
- Widget visual design beyond remaining the status surface

## Technical approach

The CLI already has separate info vs error notify helpers. Stop calling the info helper on the success path (listen started, transcribing, force-stop, cache cleaned). Keep the error helper. Do not put D-Bus notify on the recorder start path. Discover call sites and test stubs that assert the old strings.

## Tasks

- [x] Happy-path start, stop, and toggle complete without a desktop notification (acceptance: notify log / `notify-send` stub records nothing on success)
- [x] Mic, empty capture, missing paste tools, lock, and STT failures still emit a critical Dictation notification
- [x] Recovery commands (force-stop, clean, reset) do not toast on success
- [x] Automated tests that required "Écoute" / "Transcription" notify lines are updated to the errors-only contract
- [x] User-facing dictation-ptt docs list error notifications only

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| User misses listening state | Widget already polls status; do not add a new UI |
| A helper still toasts from a nested path | Grep every notify call; cover start and stop in tests |

## Test plan

Seams: CLI start/stop/toggle/recovery with a stubbed `notify-send`; status remains idle→listening→idle.

- [x] Existing dictation-ptt shell tests pass
- [x] Success path: notify stub log has no info lines
- [x] Forced error path still writes a notify line

## Verification

- [x] Lint / test per AGENTS.md (script tests if touched)
- [x] Update foam / ADR only if a new decision was made
