#!/usr/bin/env python3
"""Listen for a configured keyboard key via evdev and drive dictation-ptt.

Hold mode: KEY_DOWN → start, KEY_UP → stop.
Toggle mode: KEY_DOWN → toggle (ignore KEY_UP / autorepeat).

When possible, grab physical keyboards and re-emit all events except the PTT
key via uinput so the key never reaches the focused app (no stray glyph).
"""
from __future__ import annotations

import json
import os
import select
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    import evdev
    from evdev import UInput, ecodes
except ImportError as exc:  # pragma: no cover
    print(f"dictation-ptt-keys: missing python-evdev: {exc}", file=sys.stderr)
    sys.exit(1)

CONFIG_PATH = Path(
    os.environ.get(
        "DICTATION_CONFIG",
        Path.home() / ".config" / "dictation-ptt" / "config.json",
    )
)
DICTATION_BIN = os.environ.get("DICTATION_BIN", "dictation-ptt")

# Friendly / XKB aliases → Linux KEY_* name
KEY_ALIASES = {
    "ScrollLock": "KEY_SCROLLLOCK",
    "Scroll_Lock": "KEY_SCROLLLOCK",
    "scrolllock": "KEY_SCROLLLOCK",
    "SCROLLLOCK": "KEY_SCROLLLOCK",
    "CapsLock": "KEY_CAPSLOCK",
    "Caps_Lock": "KEY_CAPSLOCK",
    "Pause": "KEY_PAUSE",
    "Break": "KEY_PAUSE",
}

DEFAULTS = {
    "mode": "toggle",
    "keyboard_key": "Pause",
    "keyboard_daemon": True,
}

# Devices that advertise KEY_* but must never be grabbed.
SKIP_NAME_SUBSTR = (
    "yubi",
    "stream-controller",
    "virtual",
    "consumer control",
    "system control",
)


@dataclass
class TrackedDevice:
    path: str
    name: str
    dev: evdev.InputDevice
    ui: UInput | None  # None = listen-only (no grab)


def load_config() -> dict:
    cfg = dict(DEFAULTS)
    if CONFIG_PATH.is_file():
        try:
            data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                cfg.update(data)
        except (OSError, json.JSONDecodeError) as exc:
            print(f"dictation-ptt-keys: config read error: {exc}", file=sys.stderr)
    return cfg


def resolve_keycode(name: str) -> int:
    name = (name or "").strip()
    if not name or name in {".", "?"}:
        raise KeyError(f"invalid key: {name!r}")
    key_name = KEY_ALIASES.get(name, name)
    if not key_name.startswith("KEY_"):
        # Single-char punctuation is never a valid KEY_* name
        if len(key_name) == 1 and not key_name.isalnum():
            raise KeyError(f"invalid key: {name!r}")
        key_name = f"KEY_{key_name.upper()}"
    code = ecodes.ecodes.get(key_name)
    if code is None:
        raise KeyError(f"unknown key: {name!r} ({key_name})")
    if isinstance(code, tuple):
        code = code[0]
    return int(code)


def should_filter_device(dev: evdev.InputDevice, keycode: int) -> bool:
    """True if this device is a real keyboard we should grab+filter."""
    name = (dev.name or "").lower()
    if any(s in name for s in SKIP_NAME_SUBSTR):
        return False
    caps = dev.capabilities()
    keys = caps.get(ecodes.EV_KEY, [])
    if keycode not in keys:
        return False
    # Real typing keyboards have letter keys; skip mice that advertise many KEY_*.
    if ecodes.KEY_A not in keys:
        return False
    if ecodes.EV_REL in caps:
        return False
    return True


def open_tracked(dev: evdev.InputDevice, keycode: int) -> TrackedDevice:
    """Grab + uinput filter when possible; otherwise listen-only."""
    path = dev.path
    name = dev.name or path
    if not should_filter_device(dev, keycode):
        return TrackedDevice(path=path, name=name, dev=dev, ui=None)

    try:
        ui = UInput.from_device(dev, name=f"dictation-ptt:{name}"[:80])
        dev.grab()
        print(f"dictation-ptt-keys: filtering {path} ({name})", flush=True)
        return TrackedDevice(path=path, name=name, dev=dev, ui=ui)
    except OSError as exc:
        print(
            f"dictation-ptt-keys: grab/uinput failed for {path} ({name}): {exc}; "
            "listen-only (key may still type)",
            flush=True,
        )
        return TrackedDevice(path=path, name=name, dev=dev, ui=None)


def close_tracked(tracked: TrackedDevice) -> None:
    if tracked.ui is not None:
        try:
            tracked.dev.ungrab()
        except OSError:
            pass
        try:
            tracked.ui.close()
        except OSError:
            pass
    try:
        tracked.dev.close()
    except OSError:
        pass


def list_candidate_devices() -> list[evdev.InputDevice]:
    devices: list[evdev.InputDevice] = []
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except OSError:
            continue
        caps = dev.capabilities().get(ecodes.EV_KEY, [])
        if ecodes.KEY_A in caps or ecodes.KEY_SCROLLLOCK in caps or ecodes.KEY_SPACE in caps:
            devices.append(dev)
    return devices


def setup_devices(keycode: int) -> dict[int, TrackedDevice]:
    fds: dict[int, TrackedDevice] = {}
    for dev in list_candidate_devices():
        tracked = open_tracked(dev, keycode)
        fds[tracked.dev.fd] = tracked
    return fds


def run_dictation(args: Iterable[str]) -> None:
    cmd = [DICTATION_BIN, *args]
    try:
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as exc:
        print(f"dictation-ptt-keys: failed to spawn {cmd}: {exc}", file=sys.stderr)


def handle_ptt(mode: str, value: int, last_fire: float) -> float:
    """Handle key value; return updated last_fire monotonic time."""
    # 0=up 1=down 2=hold/autorepeat — ignore autorepeat
    if value == 2:
        return last_fire
    t = time.monotonic()
    if t - last_fire < 0.05 and value == 1:
        return last_fire
    if mode == "toggle":
        if value == 1:
            run_dictation(["toggle"])
            return t
        return last_fire
    if value == 1:
        run_dictation(["start"])
        return t
    if value == 0:
        run_dictation(["stop"])
        return t
    return last_fire


def wait_until_enabled(cfg_mtime: float) -> tuple[dict, float]:
    """Idle until keyboard_daemon is true again (do not exit — systemd would stay dead)."""
    print("dictation-ptt-keys: keyboard_daemon disabled; waiting for re-enable", flush=True)
    while True:
        time.sleep(1.0)
        if not CONFIG_PATH.is_file():
            continue
        try:
            mtime = CONFIG_PATH.stat().st_mtime
        except OSError:
            continue
        if mtime == cfg_mtime:
            continue
        cfg = load_config()
        if cfg.get("keyboard_daemon") is False:
            cfg_mtime = mtime
            continue
        return cfg, mtime


def main() -> int:
    cfg = load_config()
    cfg_mtime = CONFIG_PATH.stat().st_mtime if CONFIG_PATH.is_file() else 0.0
    if cfg.get("keyboard_daemon") is False:
        cfg, cfg_mtime = wait_until_enabled(cfg_mtime)

    try:
        keycode = resolve_keycode(str(cfg.get("keyboard_key", "Pause")))
    except KeyError as exc:
        print(f"dictation-ptt-keys: {exc}", file=sys.stderr)
        return 1

    mode = str(cfg.get("mode", "toggle"))

    fds = setup_devices(keycode)
    if not fds:
        print("dictation-ptt-keys: no readable keyboard devices", file=sys.stderr)
        return 1

    filtered = sum(1 for t in fds.values() if t.ui is not None)
    print(
        f"dictation-ptt-keys: watching {len(fds)} device(s) "
        f"(filtering {filtered}) key={cfg.get('keyboard_key')} "
        f"code={keycode} mode={mode}",
        flush=True,
    )

    last_fire = 0.0

    try:
        while True:
            # Hot-reload config (mode / key / enable)
            if CONFIG_PATH.is_file():
                try:
                    mtime = CONFIG_PATH.stat().st_mtime
                except OSError:
                    mtime = cfg_mtime
                if mtime != cfg_mtime:
                    cfg_mtime = mtime
                    cfg = load_config()
                    if cfg.get("keyboard_daemon") is False:
                        for tracked in list(fds.values()):
                            close_tracked(tracked)
                        fds = {}
                        cfg, cfg_mtime = wait_until_enabled(cfg_mtime)
                        try:
                            keycode = resolve_keycode(str(cfg.get("keyboard_key", "Pause")))
                        except KeyError as exc:
                            print(f"dictation-ptt-keys: {exc}", file=sys.stderr)
                            return 1
                        mode = str(cfg.get("mode", "toggle"))
                        fds = setup_devices(keycode)
                        print(
                            f"dictation-ptt-keys: re-enabled watching {len(fds)} "
                            f"key={cfg.get('keyboard_key')} mode={mode}",
                            flush=True,
                        )
                        continue
                    try:
                        new_code = resolve_keycode(str(cfg.get("keyboard_key", "Pause")))
                        mode = str(cfg.get("mode", "toggle"))
                        if new_code != keycode:
                            keycode = new_code
                            for tracked in list(fds.values()):
                                close_tracked(tracked)
                            fds = setup_devices(keycode)
                            print(
                                f"dictation-ptt-keys: reloaded key={cfg.get('keyboard_key')} "
                                f"mode={mode} devices={len(fds)}",
                                flush=True,
                            )
                        else:
                            print(
                                f"dictation-ptt-keys: reloaded config key={cfg.get('keyboard_key')} "
                                f"mode={mode}",
                                flush=True,
                            )
                    except KeyError as exc:
                        # Keep previous keycode/mode — a bad DMS edit must not kill the daemon.
                        print(
                            f"dictation-ptt-keys: ignoring bad config key ({exc}); "
                            f"keeping previous binding",
                            flush=True,
                        )

            if not fds:
                time.sleep(1.0)
                fds = setup_devices(keycode)
                if fds:
                    print(f"dictation-ptt-keys: re-acquired {len(fds)} device(s)", flush=True)
                continue

            r, _, _ = select.select(list(fds.keys()), [], [], 1.0)
            for fd in r:
                tracked = fds[fd]
                try:
                    for event in tracked.dev.read():
                        if event.type == ecodes.EV_KEY and event.code == keycode:
                            last_fire = handle_ptt(mode, event.value, last_fire)
                            # Swallow: do not forward PTT key through uinput.
                            continue
                        if tracked.ui is not None:
                            tracked.ui.write_event(event)
                except OSError:
                    # Device unplugged
                    try:
                        del fds[fd]
                    except KeyError:
                        pass
                    close_tracked(tracked)
                    print(f"dictation-ptt-keys: lost device {tracked.path}", flush=True)
    finally:
        for tracked in list(fds.values()):
            close_tracked(tracked)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
