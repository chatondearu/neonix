# Design: dictation-ptt keyboard daemon (evdev PTT)

Date: 2026-08-29  
Status: approved for implementation  
Extends: `2026-08-29-dictation-ptt-reliability-controls-design.md`

## Goal

Provide real keyboard push-to-talk (press/release) independent of niri bind limitations, keep Stream Deck in sync with DMS mode, and make the bar widget toggle reliable.

## Architecture

```text
  Scroll_Lock (hardware)
        │
        ▼
  dictation-ptt-keys  (python-evdev user service)
        │  hold: start/stop   toggle: toggle on down
        ▼
  dictation-ptt CLI  ←── Stream Deck / DMS widget
```

- User is already in group `input` → can open `/dev/input/event*`.
- Config: `~/.config/dictation-ptt/config.json` (existing keys + `keyboard_daemon: true`).
- niri: do not use press-only hold binds; optional toggle-only fallback when daemon disabled.
- DMS `write-cli-config.sh`: write config → sync niri → install Stream Deck fragment → `systemctl --user try-restart dictation-ptt-keys`.

## Daemon behavior

| Mode | KEY_DOWN | KEY_UP |
|------|----------|--------|
| hold | `dictation-ptt start` | `dictation-ptt stop` |
| toggle | `dictation-ptt toggle` | ignore |

- Debounce identical events &lt; 50 ms.
- Ignore autorepeat (EV_KEY value 2).
- Map friendly names (`ScrollLock`) → Linux keycode (`KEY_SCROLLLOCK`).
- Hot-reload config on mtime change (poll 1 s).

## Non-goals

- Exclusive key grab (ScrollLock may still reach focused apps).
- Changing STT backends from the daemon.

## Acceptance

1. Hold ScrollLock: record while held, stop+transcribe on release.
2. Toggle mode: one press starts, next stops.
3. Changing mode in DMS updates Stream Deck fragment without manual install (restart StreamController still required once).
4. Widget click toggles once and shows listening within ~400 ms.
