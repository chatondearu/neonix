---
title: "feat(dictation-ptt): stream local STT while recording; flush on release"
status: in-progress
priority: P0
updated: 2026-11-25
github_issue: 31
blocked_by: [30]
---

## Goal

Feed PCM to a local streaming ASR while PTT is held; on release flush and paste.

## Acceptance

- [ ] Streaming engine consumes PCM before key-up
- [ ] Release does not wait for a full-file HTTP POST of the whole clip
- [ ] No cloud STT, no live overlay
- [ ] BLOCKED rather than a fake chunked full-file loop if no engine fits
