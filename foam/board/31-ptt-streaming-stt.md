---
title: "feat(dictation-ptt): stream local STT while recording; flush on release"
status: done
priority: P0
updated: 2026-11-25
github_issue: 31
blocked_by: [30]
---

## Goal

Feed PCM to a local streaming ASR while PTT is held; on release flush and paste.

## Acceptance

- [x] Streaming engine consumes PCM before key-up
- [x] Release does not wait for a full-file HTTP POST of the whole clip
- [x] No cloud STT, no live overlay
- [x] Engine chosen: whisper-stream + ggml-small (ADR-006)
