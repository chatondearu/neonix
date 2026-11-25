---
title: "fix(dictation-ptt): drop happy-path notifications; keep errors only"
status: in-review
priority: P0
updated: 2026-11-25
github_issue: 30
---

## Goal

Happy-path dictation PTT does not fire desktop notifications; errors still do.

## Acceptance

- [ ] Start / stop / toggle happy path: no desktop notification
- [ ] Error paths still notify (critical)
- [ ] Widget remains the status UI
- [ ] Tests and README match
