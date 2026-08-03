# Stream Deck PTT STT Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Wyoming/llama-swap black spots, then ship hold-to-talk dictation from Stream Deck into the focused Wayland window via local faster-whisper, with desktop notifications on failures.

**Architecture:** Phase 0 hardens existing NixOS Wyoming + llama-swap services (localhost, CUDA, FR bias, memory limits, package bump). Phase 1 adds a `dictation-ptt` CLI (`start`/`stop`) that records with `pw-record`, transcribes over Wyoming TCP, pastes with `wl-copy`+`wtype`, and calls `notify-send` on errors. StreamController binds press→start and release→stop.

**Tech Stack:** NixOS modules (`dev/ai.nix`), llama-swap prebuilt update, PipeWire `pw-record`, Python `wyoming` client, `libnotify`, `wl-clipboard`, `wtype`, StreamController shell actions.

**Spec:** `docs/superpowers/specs/2026-08-03-streamdeck-ptt-stt-design.md`

## Global Constraints

- Hold-to-talk only (press=start, release=stop); no toggle
- STT backend: existing Wyoming faster-whisper on `127.0.0.1:10300`
- Language: `fr` + technical `initialPrompt`; device: `cuda` (fallback to `cpu` only if CUDA fails at runtime)
- Notifications: `notify-send` title `Dictation` on mic/STT/model/process failures; no success toast by default
- Do not change Piper voice; do not remove Flatpak StreamController remnant; do not remove VR UDP 10400
- Comments in code: English; user-facing notification body: French OK
- Conventional Commits for git messages

## File structure

| Path | Responsibility |
|------|----------------|
| `dev/ai.nix` | Wyoming/firewall/memory overrides; install `dictation-ptt` |
| `pkgs/llama-swap/sources.json` | Bumped llama-swap version/hash |
| `scripts/ai/dictation-ptt/dictation-ptt.sh` | `start`/`stop` orchestration, state files, notify, paste |
| `scripts/ai/dictation-ptt/wyoming_transcribe.py` | WAV/PCM → Wyoming → stdout text |
| `pkgs/dictation-ptt/default.nix` | Wrap script + python + runtime deps |
| `scripts/ai/dictation-ptt/README.md` | StreamController binding instructions |
| `scripts/ai/dictation-ptt/test_wyoming_transcribe.py` | Unit tests for transcript parsing / error paths (mocked) |

---

### Task 1: Phase 0 — Harden Wyoming in `dev/ai.nix`

**Files:**
- Modify: `dev/ai.nix`

**Interfaces:**
- Consumes: NixOS `services.wyoming.*` module options (`initialPrompt`, `device`, `language`, `uri`)
- Produces: Whisper on `tcp://127.0.0.1:10300`, CUDA, `fr`, memory limits on unit `wyoming-faster-whisper-english`

- [ ] **Step 1: Replace the Whisper + memory + firewall + bind sections**

Replace the Wyoming block and related overrides in `dev/ai.nix` so the file contains (keep ollama commented block and packages/sessionVariables as they are):

```nix
  services.wyoming.faster-whisper = {
    servers.english = {
      enable = true;
      model = "large-v3-turbo";
      language = "fr";
      device = "cuda";
      uri = "tcp://127.0.0.1:10300";
      initialPrompt = "Dictée technique en français. Termes possibles : API, commit, pull request, TypeScript, NixOS, flake, props, endpoint.";
    };
  };

  systemd.services.wyoming-faster-whisper-english = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      MemoryMax = "16G";
      MemoryHigh = "14G";
    };
  };

  services.wyoming.piper.servers.yoda = {
    enable = true;
    voice = "en-us-ryan-high";
    uri = "tcp://127.0.0.1:10200";
    useCUDA = true;
  };

  services.wyoming.openwakeword = {
    enable = true;
    uri = "tcp://127.0.0.1:10400";
  };

  networking.firewall.allowedTCPPorts = [
    # 11434 # Ollama
    61337
  ];
```

Also update the top cost comment to say Whisper prefers CUDA when `ctranslate2` supports it.

- [ ] **Step 2: Sanity-check evaluation (no full rebuild yet)**

Run:

```bash
cd /home/chaton/etc/nixos
nixos-rebuild dry-activate --flake .#neo-nix 2>&1 | tee /tmp/ptt-phase0-dry.log | tail -40
```

Expected: succeeds or only shows known unrelated warnings; must **not** reference `wyoming-faster-whisper-main` as a configured unit override for memory.

- [ ] **Step 3: Commit**

```bash
git add dev/ai.nix
git commit -m "$(cat <<'EOF'
fix(ai): harden Wyoming listeners, FR CUDA whisper, memory limits

Bind voice stack to localhost, force French STT bias, target the real
whisper unit for MemoryMax, and drop unused Wyoming firewall ports.
EOF
)"
```

---

### Task 2: Phase 0 — Update llama-swap to latest

**Files:**
- Modify: `pkgs/llama-swap/sources.json` (via update script)
- Possibly: `pkgs/llama-swap/default.nix` only if version wiring changes (normally untouched)

**Interfaces:**
- Consumes: GitHub latest release for `mostlygeek/llama-swap`
- Produces: newer `pkgs.llama-swap` used by `dev/ai-llama.nix`

- [ ] **Step 1: Run package update**

```bash
cd /home/chaton/etc/nixos
bash pkgs/llama-swap/update.sh
cat pkgs/llama-swap/sources.json
```

Expected: `version` newer than `224` (e.g. `246`), new `hash`.

- [ ] **Step 2: Build the package**

```bash
nix build .#llama-swap -L 2>&1 | tee /tmp/llama-swap-build.log | tail -30
./result/bin/llama-swap --version 2>&1 || ./result/bin/llama-swap -h 2>&1 | head -5
```

Expected: build succeeds; binary present.

- [ ] **Step 3: Commit**

```bash
git add pkgs/llama-swap/sources.json
git commit -m "$(cat <<'EOF'
chore(pkgs): bump llama-swap to latest release

Keep the OpenAI-compatible proxy current before dictation work.
EOF
)"
```

---

### Task 3: Phase 0 — Apply system and verify services

**Files:**
- None (runtime verification)

**Interfaces:**
- Consumes: Tasks 1–2 config
- Produces: Confirmed healthy Whisper + llama-swap for Phase 1

- [ ] **Step 1: Switch configuration**

```bash
cd /home/chaton/etc/nixos
sudo nixos-rebuild switch --flake .#neo-nix 2>&1 | tee /tmp/ptt-phase0-switch.log | tail -50
```

Expected: switch completes. If Whisper fails because ctranslate2 lacks CUDA, capture journal, set `device = "cpu"` in a follow-up commit in this task, re-switch, and note the fallback in the commit message.

- [ ] **Step 2: Verify units and binds**

```bash
systemctl status wyoming-faster-whisper-english --no-pager
systemctl show wyoming-faster-whisper-english -p MemoryMax,MemoryHigh,ActiveState --no-pager
systemctl show wyoming-faster-whisper-main -p LoadState --no-pager
ss -ltnp | rg '10300|10200|10400|9292'
journalctl -u wyoming-faster-whisper-english -n 40 --no-pager
curl -sS -m 2 http://127.0.0.1:9292/v1/models | head -c 200; echo
```

Expected:
- `wyoming-faster-whisper-english` active; `MemoryMax` not infinity
- `wyoming-faster-whisper-main` absent or not carrying the memory override (`LoadState=not-found` or unused)
- Listeners on `127.0.0.1` for 10200/10300/10400 (not `0.0.0.0`)
- Journal: Ready; prefer no float32 CPU conversion warning when CUDA works
- llama-swap `/v1/models` returns JSON

- [ ] **Step 3: Commit only if CUDA fallback edit was required**

If `device` had to revert to `cpu`:

```bash
git add dev/ai.nix
git commit -m "$(cat <<'EOF'
fix(ai): fall back Whisper to CPU when CUDA ctranslate2 unavailable

Keep dictation unblocked; GPU STT remains the preferred target.
EOF
)"
```

Otherwise no commit.

---

### Task 4: Phase 1 — Wyoming transcribe helper + unit tests

**Files:**
- Create: `scripts/ai/dictation-ptt/wyoming_transcribe.py`
- Create: `scripts/ai/dictation-ptt/test_wyoming_transcribe.py`

**Interfaces:**
- Consumes: WAV file path (16-bit PCM mono preferred), URI `tcp://127.0.0.1:10300`, language `fr`
- Produces: transcript text on stdout; non-zero exit + stderr message on failure; exit code `2` for empty transcript

- [ ] **Step 1: Write failing tests**

Create `scripts/ai/dictation-ptt/test_wyoming_transcribe.py`:

```python
import asyncio
import wave
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

import wyoming_transcribe as wt


def _write_silent_wav(path: Path, seconds: float = 0.2, rate: int = 16000) -> None:
    frames = int(rate * seconds)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(rate)
        wf.writeframes(b"\x00\x00" * frames)


@pytest.mark.asyncio
async def test_transcribe_returns_text(tmp_path: Path) -> None:
    wav = tmp_path / "a.wav"
    _write_silent_wav(wav)

    mock_client = AsyncMock()
    mock_client.__aenter__.return_value = mock_client
    mock_client.__aexit__.return_value = None
    mock_client.write_event = AsyncMock()

    from wyoming.asr import Transcript

    mock_client.read_event = AsyncMock(
        side_effect=[Transcript(text="bonjour monde").event(), None]
    )

    with patch.object(wt, "AsyncClient") as client_cls:
        client_cls.from_uri.return_value = mock_client
        text = await wt.transcribe_file(wav, "tcp://127.0.0.1:10300", language="fr")

    assert text == "bonjour monde"


@pytest.mark.asyncio
async def test_transcribe_propagates_wyoming_error(tmp_path: Path) -> None:
    wav = tmp_path / "a.wav"
    _write_silent_wav(wav)

    mock_client = AsyncMock()
    mock_client.__aenter__.return_value = mock_client
    mock_client.__aexit__.return_value = None
    mock_client.write_event = AsyncMock()

    from wyoming.error import Error

    mock_client.read_event = AsyncMock(
        side_effect=[Error(text="model failed", code="MODEL_ERROR").event(), None]
    )

    with patch.object(wt, "AsyncClient") as client_cls:
        client_cls.from_uri.return_value = mock_client
        with pytest.raises(wt.TranscribeError, match="model failed"):
            await wt.transcribe_file(wav, "tcp://127.0.0.1:10300", language="fr")
```

- [ ] **Step 2: Run tests (expect fail — module missing)**

```bash
cd /home/chaton/etc/nixos/scripts/ai/dictation-ptt
nix-shell -p python3 python3Packages.pytest python3Packages.pytest-asyncio python3Packages.wyoming --run \
  'pytest -q test_wyoming_transcribe.py'
```

Expected: FAIL importing `wyoming_transcribe` or missing symbols.

- [ ] **Step 3: Implement `wyoming_transcribe.py`**

```python
#!/usr/bin/env python3
"""Send a WAV file to a Wyoming ASR server and print the transcript."""

from __future__ import annotations

import argparse
import asyncio
import sys
import wave
from pathlib import Path

from wyoming.asr import Transcribe, Transcript
from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.client import AsyncClient
from wyoming.error import Error


class TranscribeError(RuntimeError):
    """Wyoming or I/O failure during transcription."""


async def transcribe_file(
    wav_path: Path,
    uri: str,
    *,
    language: str = "fr",
    chunk_ms: int = 100,
) -> str:
    with wave.open(str(wav_path), "rb") as wf:
        rate = wf.getframerate()
        width = wf.getsampwidth()
        channels = wf.getnchannels()
        frames = wf.readframes(wf.getnframes())

    if width != 2 or channels != 1:
        raise TranscribeError(
            f"expected mono 16-bit PCM WAV, got width={width} channels={channels}"
        )

    bytes_per_chunk = max(rate * width * channels * chunk_ms // 1000, width)

    async with AsyncClient.from_uri(uri) as client:
        await client.write_event(Transcribe(language=language).event())
        await client.write_event(
            AudioStart(rate=rate, width=width, channels=channels).event()
        )

        for offset in range(0, len(frames), bytes_per_chunk):
            chunk = frames[offset : offset + bytes_per_chunk]
            await client.write_event(
                AudioChunk(
                    rate=rate, width=width, channels=channels, audio=chunk
                ).event()
            )

        await client.write_event(AudioStop().event())

        while True:
            event = await client.read_event()
            if event is None:
                raise TranscribeError("Wyoming connection closed before transcript")
            if Error.is_type(event.type):
                err = Error.from_event(event)
                raise TranscribeError(err.text or err.code or "Wyoming error")
            if Transcript.is_type(event.type):
                return Transcript.from_event(event).text.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wav", type=Path)
    parser.add_argument(
        "--uri",
        default="tcp://127.0.0.1:10300",
        help="Wyoming ASR URI",
    )
    parser.add_argument("--language", default="fr")
    args = parser.parse_args()

    try:
        text = asyncio.run(transcribe_file(args.wav, args.uri, language=args.language))
    except Exception as exc:  # noqa: BLE001 — CLI boundary
        print(f"transcription failed: {exc}", file=sys.stderr)
        return 1

    if not text:
        print("empty transcript", file=sys.stderr)
        return 2

    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Re-run tests**

```bash
cd /home/chaton/etc/nixos/scripts/ai/dictation-ptt
nix-shell -p python3 python3Packages.pytest python3Packages.pytest-asyncio python3Packages.wyoming --run \
  'pytest -q test_wyoming_transcribe.py'
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/ai/dictation-ptt/wyoming_transcribe.py scripts/ai/dictation-ptt/test_wyoming_transcribe.py
git commit -m "$(cat <<'EOF'
feat(ai): add Wyoming WAV transcription helper for PTT dictation

Provide a small async client used by hold-to-talk stop path.
EOF
)"
```

---

### Task 5: Phase 1 — `dictation-ptt` start/stop CLI with notifications

**Files:**
- Create: `scripts/ai/dictation-ptt/dictation-ptt.sh`

**Interfaces:**
- Consumes: `wyoming_transcribe.py`, `pw-record`, `wl-copy`, `wtype`, `notify-send`
- Produces: `dictation-ptt start|stop` CLI; state under `${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt/`

- [ ] **Step 1: Implement the shell CLI**

Create `scripts/ai/dictation-ptt/dictation-ptt.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dictation-ptt"
PID_FILE="$STATE_DIR/record.pid"
WAV_FILE="$STATE_DIR/capture.wav"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TRANSCRIBE="${DICTATION_TRANSCRIBE:-$SCRIPT_DIR/wyoming_transcribe.py}"
WYOMING_URI="${DICTATION_WYOMING_URI:-tcp://127.0.0.1:10300}"
NOTIFY_TITLE="Dictation"

notify_err() {
  local body="$1"
  echo "$NOTIFY_TITLE: $body" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical -a Dictation "$NOTIFY_TITLE" "$body" || true
  fi
}

ensure_state_dir() {
  mkdir -p "$STATE_DIR"
}

stop_recording_process() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE")"
    if kill -0 "$pid" 2>/dev/null; then
      kill -INT "$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
}

cmd_start() {
  ensure_state_dir
  # Restart cleanly if already recording
  stop_recording_process
  rm -f "$WAV_FILE"

  if ! command -v pw-record >/dev/null 2>&1; then
    notify_err "pw-record introuvable (PipeWire)."
    exit 1
  fi

  # 16 kHz mono s16 for Whisper
  pw-record --rate=16000 --channels=1 --format=s16 "$WAV_FILE" &
  echo $! >"$PID_FILE"

  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    rm -f "$PID_FILE"
    notify_err "Échec démarrage micro / PipeWire."
    exit 1
  fi
}

cmd_stop() {
  ensure_state_dir

  if [[ ! -f "$PID_FILE" ]]; then
    exit 0
  fi

  stop_recording_process

  if [[ ! -f "$WAV_FILE" ]] || [[ ! -s "$WAV_FILE" ]]; then
    notify_err "Enregistrement vide ou manquant."
    exit 1
  fi

  if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wtype >/dev/null 2>&1; then
    notify_err "wl-copy ou wtype manquant."
    exit 1
  fi

  local text rc
  set +e
  text="$(python3 "$TRANSCRIBE" --uri "$WYOMING_URI" --language fr "$WAV_FILE" 2>/tmp/dictation-ptt-transcribe.err)"
  rc=$?
  set -e

  if [[ "$rc" -eq 2 ]]; then
    # Empty transcript: no paste, no critical noise
    exit 0
  fi

  if [[ "$rc" -ne 0 ]]; then
    local err
    err="$(cat /tmp/dictation-ptt-transcribe.err 2>/dev/null || echo "erreur inconnue")"
    notify_err "STT / modèle: $err"
    exit 1
  fi

  printf '%s' "$text" | wl-copy
  # Small delay so the focused client receives clipboard before paste
  sleep 0.05
  wtype -M ctrl v -m ctrl
}

usage() {
  echo "Usage: dictation-ptt start|stop" >&2
  exit 2
}

main() {
  case "${1:-}" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    *) usage ;;
  esac
}

main "$@"
```

Make executable: `chmod +x scripts/ai/dictation-ptt/dictation-ptt.sh`

- [ ] **Step 2: Manual smoke without Stream Deck**

With Whisper up:

```bash
# Terminal A / or background
/home/chaton/etc/nixos/scripts/ai/dictation-ptt/dictation-ptt.sh start
# speak ~2s
/home/chaton/etc/nixos/scripts/ai/dictation-ptt/dictation-ptt.sh stop
```

Expected: text pasted into focused window; on failure (stop Whisper first) a `Dictation` critical notification appears.

Simulate failure:

```bash
sudo systemctl stop wyoming-faster-whisper-english
/home/chaton/etc/nixos/scripts/ai/dictation-ptt/dictation-ptt.sh start
sleep 1
/home/chaton/etc/nixos/scripts/ai/dictation-ptt/dictation-ptt.sh stop
sudo systemctl start wyoming-faster-whisper-english
```

Expected: notification about STT/model; no paste.

- [ ] **Step 3: Commit**

```bash
git add scripts/ai/dictation-ptt/dictation-ptt.sh
git commit -m "$(cat <<'EOF'
feat(ai): add hold-to-talk dictation-ptt start/stop CLI

Record via PipeWire, transcribe with Wyoming, paste at focus, and
notify on mic or model failures.
EOF
)"
```

---

### Task 6: Phase 1 — Package `dictation-ptt` in NixOS

**Files:**
- Create: `pkgs/dictation-ptt/default.nix`
- Modify: `dev/ai.nix` (add package to `environment.systemPackages`)

**Interfaces:**
- Consumes: scripts from Task 4–5
- Produces: `/run/current-system/sw/bin/dictation-ptt` with wrapped PATH/python

- [ ] **Step 1: Create the package**

`pkgs/dictation-ptt/default.nix`:

```nix
{
  lib,
  writeShellApplication,
  python3,
  pipewire,
  wl-clipboard,
  wtype,
  libnotify,
  coreutils,
  gnugrep,
}: let
  py = python3.withPackages (ps: [ps.wyoming]);
  src = ../../scripts/ai/dictation-ptt;
in
  writeShellApplication {
    name = "dictation-ptt";
    runtimeInputs = [
      py
      pipewire
      wl-clipboard
      wtype
      libnotify
      coreutils
      gnugrep
    ];
    text = ''
      export DICTATION_TRANSCRIBE="${src}/wyoming_transcribe.py"
      exec bash "${src}/dictation-ptt.sh" "$@"
    '';
  }
```

Note: if `writeShellApplication` + external bash script is awkward, alternate form is `runCommand`/`symlinkJoin` copying scripts into `$out/bin` with a wrapped python shebang. Prefer a single `$out/bin/dictation-ptt` that works offline from the store.

Preferred robust variant if the above path reference is impure for pure eval — **vendor scripts into the derivation**:

```nix
{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  pipewire,
  wl-clipboard,
  wtype,
  libnotify,
  bash,
}: let
  py = python3.withPackages (ps: [ps.wyoming]);
in
  stdenvNoCC.mkDerivation {
    pname = "dictation-ptt";
    version = "0.1.0";
    src = ../../scripts/ai/dictation-ptt;
    nativeBuildInputs = [makeWrapper];
    installPhase = ''
      mkdir -p $out/lib/dictation-ptt $out/bin
      cp -r . $out/lib/dictation-ptt/
      makeWrapper ${bash}/bin/bash $out/bin/dictation-ptt \
        --prefix PATH : ${lib.makeBinPath [py pipewire wl-clipboard wtype libnotify]} \
        --set DICTATION_TRANSCRIBE $out/lib/dictation-ptt/wyoming_transcribe.py \
        --add-flags "$out/lib/dictation-ptt/dictation-ptt.sh"
    '';
    meta = {
      description = "Hold-to-talk dictation via Wyoming faster-whisper";
      mainProgram = "dictation-ptt";
    };
  }
```

Use this robust variant in the implementation.

- [ ] **Step 2: Wire into `dev/ai.nix`**

Add to `environment.systemPackages`:

```nix
    (callPackage ../pkgs/dictation-ptt/default.nix {})
```

- [ ] **Step 3: Build and switch**

```bash
cd /home/chaton/etc/nixos
nix build -L --impure -f pkgs/dictation-ptt/default.nix 2>&1 | tee /tmp/dictation-ptt-build.log | tail -20
# or via flake/system:
sudo nixos-rebuild switch --flake .#neo-nix 2>&1 | tee /tmp/ptt-phase1-switch.log | tail -40
command -v dictation-ptt
dictation-ptt 2>&1 | head -5
```

Expected: `dictation-ptt` on PATH; usage message for missing args.

- [ ] **Step 4: Commit**

```bash
git add pkgs/dictation-ptt/default.nix dev/ai.nix
git commit -m "$(cat <<'EOF'
feat(ai): package dictation-ptt for system PATH

Expose the hold-to-talk CLI to StreamController with wrapped deps.
EOF
)"
```

---

### Task 7: StreamController wiring docs + end-to-end check

**Files:**
- Create: `scripts/ai/dictation-ptt/README.md`
- Modify: `scripts/ai/README.md` (one-line link to dictation-ptt)

**Interfaces:**
- Consumes: installed `dictation-ptt`
- Produces: documented press/release actions for StreamController

- [ ] **Step 1: Write README**

`scripts/ai/dictation-ptt/README.md`:

```markdown
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
```

- [ ] **Step 2: Bind in StreamController UI** (manual; operator)

Configure press/release as above. No Nix change required if PATH works.

- [ ] **Step 3: End-to-end test**

1. Focus a text editor
2. Hold Stream Deck button, speak French + English tech terms, release
3. Confirm paste
4. Stop Whisper service, retry → notification, no paste
5. Start Whisper again

- [ ] **Step 4: Commit docs**

```bash
git add scripts/ai/dictation-ptt/README.md scripts/ai/README.md
git commit -m "$(cat <<'EOF'
docs(ai): document StreamController wiring for dictation-ptt

EOF
)"
```

---

## Self-review vs spec

| Spec item | Task |
|-----------|------|
| Memory override on `english` unit | Task 1 |
| CUDA + `fr` + initialPrompt | Task 1 |
| Localhost Wyoming binds | Task 1 |
| Drop unused TCP firewall ports | Task 1 |
| llama-swap bump | Task 2 |
| CUDA runtime fallback | Task 3 |
| Hold-to-talk start/stop | Task 5 |
| Wyoming STT + paste | Tasks 4–5 |
| Desktop notifications on failures | Task 5 |
| Package on PATH + StreamController | Tasks 6–7 |
| Deferred Piper/Flatpak/wake-agent | Explicitly omitted |

No TBD placeholders remain. Notification title fixed as `Dictation`. Paste strategy fixed as `wl-copy` + `wtype` Ctrl+v.
