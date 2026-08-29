#!/usr/bin/env python3
"""Listen for a configured keyboard key via evdev and drive dictation-ptt.

Hold mode: KEY_DOWN → start, KEY_UP → stop.
Toggle mode: KEY_DOWN → toggle (ignore KEY_UP / autorepeat).
"""
from __future__ import annotations

import json
import os
import select
import subprocess
import sys
import time
from pathlib import Path
from typing import Iterable

try:
    import evdev
    from evdev import ecodes
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
    "mode": "hold",
    "keyboard_key": "ScrollLock",
    "keyboard_daemon": True,
}


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
    key_name = KEY_ALIASES.get(name, name)
    if not key_name.startswith("KEY_"):
        key_name = f"KEY_{key_name.upper()}"
    code = ecodes.ecodes.get(key_name)
    if code is None:
        raise KeyError(f"unknown key: {name!r} ({key_name})")
    if isinstance(code, tuple):
        code = code[0]
    return int(code)


def list_keyboards() -> list[evdev.InputDevice]:
    devices: list[evdev.InputDevice] = []
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except OSError:
            continue
        caps = dev.capabilities().get(ecodes.EV_KEY, [])
        # Prefer devices that look like keyboards (have letter keys or ScrollLock).
        if ecodes.KEY_A in caps or ecodes.KEY_SCROLLLOCK in caps or ecodes.KEY_SPACE in caps:
            devices.append(dev)
    return devices


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


def main() -> int:
    cfg = load_config()
    if cfg.get("keyboard_daemon") is False:
        print("dictation-ptt-keys: keyboard_daemon disabled in config; exiting", file=sys.stderr)
        return 0

    try:
        keycode = resolve_keycode(str(cfg.get("keyboard_key", "ScrollLock")))
    except KeyError as exc:
        print(f"dictation-ptt-keys: {exc}", file=sys.stderr)
        return 1

    mode = str(cfg.get("mode", "hold"))
    cfg_mtime = CONFIG_PATH.stat().st_mtime if CONFIG_PATH.is_file() else 0.0

    devices = list_keyboards()
    if not devices:
        print("dictation-ptt-keys: no readable keyboard devices", file=sys.stderr)
        return 1

    print(
        f"dictation-ptt-keys: watching {len(devices)} device(s) "
        f"key={cfg.get('keyboard_key')} code={keycode} mode={mode}",
        flush=True,
    )

    last_fire = 0.0
    fds = {dev.fd: dev for dev in devices}

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
                    print("dictation-ptt-keys: disabled via config; exiting", flush=True)
                    return 0
                try:
                    keycode = resolve_keycode(str(cfg.get("keyboard_key", "ScrollLock")))
                except KeyError as exc:
                    print(f"dictation-ptt-keys: {exc}", file=sys.stderr)
                    return 1
                mode = str(cfg.get("mode", "hold"))
                print(
                    f"dictation-ptt-keys: reloaded config key={cfg.get('keyboard_key')} "
                    f"mode={mode}",
                    flush=True,
                )

        r, _, _ = select.select(list(fds.keys()), [], [], 1.0)
        for fd in r:
            dev = fds[fd]
            try:
                for event in dev.read():
                    if event.type != ecodes.EV_KEY:
                        continue
                    if event.code != keycode:
                        continue
                    # 0=up 1=down 2=hold/autorepeat — ignore autorepeat
                    if event.value == 2:
                        continue
                    t = time.monotonic()
                    if t - last_fire < 0.05 and event.value == 1:
                        continue
                    last_fire = t
                    if mode == "toggle":
                        if event.value == 1:
                            run_dictation(["toggle"])
                    else:
                        if event.value == 1:
                            run_dictation(["start"])
                        elif event.value == 0:
                            run_dictation(["stop"])
            except OSError:
                # Device unplugged
                try:
                    del fds[fd]
                except KeyError:
                    pass
                print(f"dictation-ptt-keys: lost device {dev.path}", flush=True)

        # Rescan if we lost all devices
        if not fds:
            time.sleep(1.0)
            devices = list_keyboards()
            fds = {dev.fd: dev for dev in devices}
            if fds:
                print(f"dictation-ptt-keys: re-acquired {len(fds)} device(s)", flush=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
