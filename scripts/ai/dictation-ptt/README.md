# dictation-ptt

Hold-to-talk local dictation: PipeWire record → Wyoming faster-whisper → paste at focus.

## StreamController

1. Create a button on your Stream Deck profile.
2. Add action **press** (or key down): `dictation-ptt start`
3. Add action **release** (or key up): `dictation-ptt stop`
4. Prefer running StreamController from the Nix package (not the old Flatpak) so PATH matches the system.

## Failures

Desktop notifications titled **Dictation** appear for mic/PipeWire issues, missing paste tools, and STT/model errors. Empty transcripts do not notify and do not paste.

## Manual test

```bash
dictation-ptt start
# speak
dictation-ptt stop
```
