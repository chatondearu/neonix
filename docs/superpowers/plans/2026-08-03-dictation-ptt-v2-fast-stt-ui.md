# dictation-ptt v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep `dictation-ptt` as the orchestrator, add always-on DMS status + notifications, and switch default STT to Parakeet (OpenAI HTTP) with whisper.cpp CUDA and Wyoming as fallbacks for ≤3 s short-clip latency.

**Architecture:** Extend the bash CLI with status/toggle and replace-id notifications; add a small DMS bar plugin that polls status and toggles recording. Introduce an OpenAI `/v1/audio/transcriptions` client with backend order `parakeet → whisper → wyoming`. Package `achetronic/parakeet` (Go/ONNX) on `127.0.0.1:10310` and a standalone whisper.cpp CUDA server on `127.0.0.1:10311`.

**Tech Stack:** bash, Python (httpx + existing wyoming), DMS Quickshell plugin (QML), NixOS systemd, achetronic/parakeet (prebuilt), whisper.cpp CUDA, notify-send.

**Spec:** `docs/superpowers/specs/2026-08-03-dictation-ptt-v2-fast-stt-ui-design.md`

## Global Constraints

- Keep `dictation-ptt` as the single orchestration entrypoint (no Voxtype/OmniVoice primary UX)
- Notifications title exactly `Dictation`; start = « Écoute… »; transcribe begin = « Transcription… »; errors critical; no success toast by default
- Always-visible indicator (idle/listening/transcribing); no show/hide flicker
- Default STT: Parakeet when healthy; then whisper.cpp CUDA; then Wyoming
- Bind new servers to `127.0.0.1` only; do not open new firewall ports
- Short utterance target ≤ 3 s wall time from release to paste on healthy Parakeet/CUDA path
- STT timeout 60 s → notify error, no paste
- English code comments; French OK for notification bodies
- Conventional Commits
- Document Parakeet CC-BY-4.0 attribution in README

## Resolved design choices

1. **Parakeet server:** `achetronic/parakeet` (Go + ONNX, OpenAI-compatible). Prefer upstream release binary + model cache under `/hdd/parakeet` (same pattern as `pkgs/llama-swap`).
2. **Always-on UI first:** DMS plugin under `desktop/dank-material-shell/plugins/DictationPtt/` (managed via nix-maid like other DMS files). No SNI unless DMS plugin blocked.
3. **whisper.cpp:** standalone systemd service (not via llama-swap) to avoid LLM VRAM contention.

## File structure

| Path | Responsibility |
|------|----------------|
| `scripts/ai/dictation-ptt/dictation-ptt.sh` | start/stop/toggle/status + notify + STT route |
| `scripts/ai/dictation-ptt/openai_transcribe.py` | OpenAI multipart client |
| `scripts/ai/dictation-ptt/wyoming_transcribe.py` | Legacy Wyoming client (keep) |
| `scripts/ai/dictation-ptt/test_openai_transcribe.py` | Unit tests for OpenAI client |
| `scripts/ai/dictation-ptt/test_dictation_state.sh` | Shell tests for status file transitions |
| `pkgs/dictation-ptt/default.nix` | Wrap updated scripts + curl/httpx |
| `pkgs/parakeet-asr/default.nix` + `sources.json` + `update.sh` | Prebuilt Parakeet server |
| `dev/ai-stt.nix` | systemd units Parakeet + whisper.cpp |
| `dev/ai.nix` | import `ai-stt.nix`, keep Wyoming |
| `desktop/dank-material-shell/plugins/DictationPtt/*` | DMS always-on widget |
| `scripts/ai/dictation-ptt/README.md` | backends, attribution, Stream Deck, widget |

---

### Task 1: Status file + notifications + toggle/status CLI

**Files:**
- Modify: `scripts/ai/dictation-ptt/dictation-ptt.sh`
- Create: `scripts/ai/dictation-ptt/test_dictation_state.sh`
- Modify: `pkgs/dictation-ptt/default.nix` (only if PATH deps change — usually not yet)

**Interfaces:**
- Consumes: existing start/stop recording logic
- Produces:
  - `$STATE_DIR/state` containing exactly one of `idle|listening|transcribing`
  - `dictation-ptt status` → prints that word + exit 0
  - `dictation-ptt toggle` → start if idle, stop if listening
  - `notify_info` / `notify_err` using `notify-send -r 991031` (stable replace id `991031`)

- [ ] **Step 1: Write failing shell test**

Create `scripts/ai/dictation-ptt/test_dictation_state.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname "$0")" && pwd)"
export XDG_RUNTIME_DIR="${TMPDIR:-/tmp}/dictation-ptt-test-$$"
mkdir -p "$XDG_RUNTIME_DIR"
# Stub notify-send
export PATH="$XDG_RUNTIME_DIR/bin:$PATH"
mkdir -p "$XDG_RUNTIME_DIR/bin"
cat >"$XDG_RUNTIME_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NOTIFY:$*" >>"${XDG_RUNTIME_DIR}/notify.log"
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/notify-send"

# Point script at a fake pw-record that writes silence wav then sleeps
cat >"$XDG_RUNTIME_DIR/bin/pw-record" <<'EOF'
#!/usr/bin/env bash
# args end with output path
out="${@: -1}"
python3 - <<PY
import wave, sys
p = sys.argv[1]
with wave.open(p, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(16000)
    w.writeframes(b"\x00\x00" * 16000)
PY
"$out"
sleep 30
EOF
chmod +x "$XDG_RUNTIME_DIR/bin/pw-record"

# Stub wl-copy/wtype and python transcribe to avoid real STT
export DICTATION_TRANSCRIBE="$XDG_RUNTIME_DIR/fake_transcribe.py"
cat >"$DICTATION_TRANSCRIBE" <<'EOF'
#!/usr/bin/env python3
import sys
print("bonjour")
sys.exit(0)
EOF
chmod +x "$DICTATION_TRANSCRIBE"
# Force script to use stubs: copy script and inject early PATH — run real script with PATH

"$ROOT/dictation-ptt.sh" status | grep -qx idle
"$ROOT/dictation-ptt.sh" start
"$ROOT/dictation-ptt.sh" status | grep -qx listening
grep -q "Écoute" "$XDG_RUNTIME_DIR/notify.log"
# stop will call python3 DICTATION_TRANSCRIBE — ensure python3 on PATH
export DICTATION_STT=wyoming
# Temporarily patch: the script still calls wyoming_transcribe via DICTATION_TRANSCRIBE
"$ROOT/dictation-ptt.sh" stop
"$ROOT/dictation-ptt.sh" status | grep -qx idle
grep -q "Transcription" "$XDG_RUNTIME_DIR/notify.log"
echo OK
```

- [ ] **Step 2: Run test (expect fail — no status/toggle/notify_info yet)**

```bash
chmod +x scripts/ai/dictation-ptt/test_dictation_state.sh
bash scripts/ai/dictation-ptt/test_dictation_state.sh
```

Expected: FAIL (`status` unknown / idle file missing).

- [ ] **Step 3: Implement status + notifications in `dictation-ptt.sh`**

Add near top (after STATE_DIR):

```bash
STATE_FILE="$STATE_DIR/state"
NOTIFY_ID=991031

set_state() {
  ensure_state_dir
  printf '%s\n' "$1" >"$STATE_FILE"
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    tr -d '\n' <"$STATE_FILE"
  else
    printf 'idle'
  fi
}

notify_info() {
  local body="$1"
  echo "$NOTIFY_TITLE: $body" >&2
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -r "$NOTIFY_ID" -u low -a Dictation "$NOTIFY_TITLE" "$body" || true
  fi
}

# update notify_err to also use -r "$NOTIFY_ID" -u critical
```

In `cmd_start`, after successful `pw-record` spawn:

```bash
  set_state listening
  notify_info "Écoute…"
```

In `cmd_stop`, after validating WAV and tools, **before** STT:

```bash
  set_state transcribing
  notify_info "Transcription…"
```

After successful paste (and on empty transcript / errors), always:

```bash
  set_state idle
```

Also set `idle` at start of `cmd_start` before recording only after stopping previous; on early errors set `idle`.

Add:

```bash
cmd_status() {
  get_state
  echo
}

cmd_toggle() {
  case "$(get_state)" in
    listening) cmd_stop ;;
    transcribing) echo "Dictation: transcription en cours" >&2; exit 1 ;;
    *) cmd_start ;;
  esac
}
```

Update `usage` / `main` for `start|stop|toggle|status`.

Ensure `stop` with no PID still sets idle and exits 0.

- [ ] **Step 4: Re-run shell test**

```bash
bash scripts/ai/dictation-ptt/test_dictation_state.sh
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add scripts/ai/dictation-ptt/dictation-ptt.sh scripts/ai/dictation-ptt/test_dictation_state.sh
git commit -m "$(cat <<'EOF'
feat(ai): add dictation-ptt status, toggle, and replace-id notifications

Surface idle/listening/transcribing for the DMS widget and give audible
feedback on start and transcription.
EOF
)"
```

---

### Task 2: DMS always-on DictationPtt plugin

**Files:**
- Create: `desktop/dank-material-shell/plugins/DictationPtt/plugin.json`
- Create: `desktop/dank-material-shell/plugins/DictationPtt/DictationPtt.qml`
- Modify: `desktop/shell.dank.nix` (or existing maid DMS wiring) to symlink/copy plugin into `~/.config/DankMaterialShell/plugins/DictationPtt`

**Interfaces:**
- Consumes: `dictation-ptt status` / `dictation-ptt toggle` on PATH
- Produces: always-visible bar pill; click → toggle; color/text by state

- [ ] **Step 1: Create plugin metadata**

`desktop/dank-material-shell/plugins/DictationPtt/plugin.json`:

```json
{
  "id": "dictationPtt",
  "name": "Dictation PTT",
  "description": "Always-on hold-to-talk dictation status; click to toggle",
  "version": "0.1.0",
  "author": "chaton",
  "type": "widget"
}
```

(Adjust keys to match current DMS plugin manifest schema from https://danklinux.com/docs/dankmaterialshell/plugin-development — if the live schema differs, follow the docs’ required fields exactly.)

- [ ] **Step 2: Create bar widget QML**

`desktop/dank-material-shell/plugins/DictationPtt/DictationPtt.qml` (adapt imports to match other local DMS plugins if present; otherwise use docs pattern):

```qml
import QtQuick
import Quickshell
import qs.Modules.Plugins
import qs.Common
import qs.Widgets

PluginComponent {
    id: root
    layerNamespacePlugin: "dictation-ptt"

    property string dictationState: "idle"

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: {
            Quickshell.execDetached({
                command: ["bash", "-lc", "dictation-ptt status 2>/dev/null || echo idle"],
                // Prefer Process API if available in this DMS version:
            })
            // Use a Process {} element if Quickshell.execDetached cannot capture stdout.
        }
    }

    // Prefer Process for stdout capture:
    Process {
        id: statusProc
        command: ["dictation-ptt", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.dictationState = text.trim() || "idle"
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }

    function stateGlyph() {
        if (root.dictationState === "listening") return "⏺"
        if (root.dictationState === "transcribing") return "⏳"
        return "🎤"
    }

    function stateColor() {
        if (root.dictationState === "listening") return Theme.error || "#e64553"
        if (root.dictationState === "transcribing") return Theme.warning || "#df8e1d"
        return Theme.surfaceText
    }

    horizontalBarPill: Component {
        StyledRect {
            implicitWidth: 36
            implicitHeight: 28
            radius: Theme.cornerRadius
            color: "transparent"
            StyledText {
                anchors.centerIn: parent
                text: root.stateGlyph()
                color: root.stateColor()
                font.pixelSize: Theme.fontSizeLarge
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["dictation-ptt", "toggle"])
            }
        }
    }

    verticalBarPill: horizontalBarPill
}
```

If `Process` / `StdioCollector` names differ in the installed Quickshell, mirror an existing plugin in `~/.config/DankMaterialShell/plugins/` or DMS source. Widget must remain mounted always (only glyph/color change).

- [ ] **Step 3: Wire plugin into nix-maid DMS config**

In `desktop/shell.dank.nix` (or the file that already manages `DankMaterialShell`), add maid file copy:

```nix
users.users.chaton.maid = {
  file.xdg_config."DankMaterialShell/plugins/DictationPtt".source =
    "${self}/desktop/dank-material-shell/plugins/DictationPtt";
};
```

(Merge with existing `users.users.chaton.maid` block — do not duplicate the attribute set incorrectly.)

- [ ] **Step 4: Manual verify**

```bash
sudo nixos-rebuild switch --flake .#neo-nix
# enable plugin in DMS UI if required
dictation-ptt start   # pill should show listening color
dictation-ptt stop    # pill should show transcribing then idle
```

Expected: pill always visible; click toggles.

- [ ] **Step 5: Commit**

```bash
git add desktop/dank-material-shell/plugins/DictationPtt desktop/shell.dank.nix
git commit -m "$(cat <<'EOF'
feat(desktop): add always-on DMS DictationPtt status widget

Poll dictation-ptt state and allow click-to-toggle from the bar.
EOF
)"
```

---

### Task 3: OpenAI `/v1/audio/transcriptions` client + router

**Files:**
- Create: `scripts/ai/dictation-ptt/openai_transcribe.py`
- Create: `scripts/ai/dictation-ptt/test_openai_transcribe.py`
- Modify: `scripts/ai/dictation-ptt/dictation-ptt.sh` (STT selection)
- Modify: `pkgs/dictation-ptt/default.nix` (add `httpx` to python env; expose both scripts)

**Interfaces:**
- Consumes: WAV path; base URL like `http://127.0.0.1:10310/v1`
- Produces: transcript on stdout; exit 1 on error; exit 2 on empty
- Env: `DICTATION_STT=parakeet|whisper|wyoming|auto` (default `auto`)
- URLs: `DICTATION_PARAKEET_URL` default `http://127.0.0.1:10310/v1`, `DICTATION_WHISPER_URL` default `http://127.0.0.1:10311/v1`, Wyoming unchanged

- [ ] **Step 1: Write failing pytest**

`scripts/ai/dictation-ptt/test_openai_transcribe.py`:

```python
import io
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

import openai_transcribe as ot


def test_transcribe_parses_json_text(tmp_path: Path) -> None:
    wav = tmp_path / "a.wav"
    wav.write_bytes(b"RIFF....")  # content unused by mocked httpx
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"text": "  bonjour  "}
    mock_resp.raise_for_status = MagicMock()
    with patch.object(ot.httpx, "Client") as client_cls:
        client = MagicMock()
        client.__enter__.return_value = client
        client.__exit__.return_value = None
        client.post.return_value = mock_resp
        client_cls.return_value = client
        assert ot.transcribe_file(wav, "http://127.0.0.1:10310/v1") == "bonjour"


def test_transcribe_error_status(tmp_path: Path) -> None:
    wav = tmp_path / "a.wav"
    wav.write_bytes(b"RIFF")
    mock_resp = MagicMock()
    mock_resp.status_code = 500
    mock_resp.text = "boom"
    mock_resp.raise_for_status.side_effect = ot.httpx.HTTPStatusError(
        "err", request=MagicMock(), response=mock_resp
    )
    with patch.object(ot.httpx, "Client") as client_cls:
        client = MagicMock()
        client.__enter__.return_value = client
        client.__exit__.return_value = None
        client.post.return_value = mock_resp
        client_cls.return_value = client
        with pytest.raises(ot.TranscribeError):
            ot.transcribe_file(wav, "http://127.0.0.1:10310/v1")
```

- [ ] **Step 2: Run tests (expect fail)**

```bash
cd scripts/ai/dictation-ptt
nix-shell -p python3 python3Packages.pytest python3Packages.httpx --run 'pytest -q test_openai_transcribe.py'
```

Expected: import fail / missing module.

- [ ] **Step 3: Implement `openai_transcribe.py`**

```python
#!/usr/bin/env python3
"""POST a WAV to an OpenAI-compatible /audio/transcriptions endpoint."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import httpx


class TranscribeError(RuntimeError):
    pass


def transcribe_file(
    wav_path: Path,
    base_url: str,
    *,
    model: str = "whisper-1",
    language: str | None = "fr",
    timeout: float = 60.0,
) -> str:
    url = base_url.rstrip("/") + "/audio/transcriptions"
    data: dict[str, str] = {"model": model, "response_format": "json"}
    if language:
        data["language"] = language
    with httpx.Client(timeout=timeout) as client:
        with wav_path.open("rb") as fh:
            files = {"file": (wav_path.name, fh, "audio/wav")}
            resp = client.post(url, data=data, files=files)
        try:
            resp.raise_for_status()
        except httpx.HTTPError as exc:
            raise TranscribeError(f"{exc} body={resp.text[:500]}") from exc
        payload = resp.json()
        text = (payload.get("text") or "").strip()
        return text


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("wav", type=Path)
    p.add_argument("--base-url", required=True)
    p.add_argument("--model", default="whisper-1")
    p.add_argument("--language", default="fr")
    p.add_argument("--timeout", type=float, default=60.0)
    args = p.parse_args()
    try:
        text = transcribe_file(
            args.wav,
            args.base_url,
            model=args.model,
            language=args.language or None,
            timeout=args.timeout,
        )
    except Exception as exc:  # noqa: BLE001
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

- [ ] **Step 4: Wire router into `dictation-ptt.sh`**

Replace the single wyoming call in `cmd_stop` with:

```bash
OPENAI_TRANSCRIBE="${DICTATION_OPENAI_TRANSCRIBE:-$SCRIPT_DIR/openai_transcribe.py}"
PARAKEET_URL="${DICTATION_PARAKEET_URL:-http://127.0.0.1:10310/v1}"
WHISPER_URL="${DICTATION_WHISPER_URL:-http://127.0.0.1:10311/v1}"
STT_MODE="${DICTATION_STT:-auto}"
STT_TIMEOUT="${DICTATION_STT_TIMEOUT:-60}"

backend_up() {
  local url="$1"
  curl -fsS -m 0.3 "${url%/v1}/health" >/dev/null 2>&1 \
    || curl -fsS -m 0.3 "$url/models" >/dev/null 2>&1
}

run_openai() {
  local base="$1"
  python3 "$OPENAI_TRANSCRIBE" --base-url "$base" --language fr --timeout "$STT_TIMEOUT" "$WAV_FILE"
}

run_wyoming() {
  python3 "$TRANSCRIBE" --uri "$WYOMING_URI" --language fr "$WAV_FILE"
}

transcribe_routed() {
  case "$STT_MODE" in
    parakeet) run_openai "$PARAKEET_URL" ;;
    whisper) run_openai "$WHISPER_URL" ;;
    wyoming) run_wyoming ;;
    auto)
      if backend_up "$PARAKEET_URL"; then run_openai "$PARAKEET_URL"
      elif backend_up "$WHISPER_URL"; then run_openai "$WHISPER_URL"
      else run_wyoming
      fi
      ;;
    *) notify_err "DICTATION_STT invalide: $STT_MODE"; return 1 ;;
  esac
}
```

Then:

```bash
  set +e
  text="$(transcribe_routed 2>/tmp/dictation-ptt-transcribe.err)"
  rc=$?
  set -e
```

Add `curl` to package `runtime` PATH in `pkgs/dictation-ptt/default.nix`, and python packages `[ps.wyoming ps.httpx]`. Set both `DICTATION_TRANSCRIBE` and `DICTATION_OPENAI_TRANSCRIBE`.

- [ ] **Step 5: Re-run unit tests + rebuild package**

```bash
cd scripts/ai/dictation-ptt
nix-shell -p python3 python3Packages.pytest python3Packages.httpx --run 'pytest -q test_openai_transcribe.py'
# then rebuild system package later in Task 4/5 switch
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/ai/dictation-ptt/openai_transcribe.py scripts/ai/dictation-ptt/test_openai_transcribe.py scripts/ai/dictation-ptt/dictation-ptt.sh pkgs/dictation-ptt/default.nix
git commit -m "$(cat <<'EOF'
feat(ai): route dictation-ptt through OpenAI-compatible STT backends

Add httpx client and auto fallback order parakeet → whisper → wyoming.
EOF
)"
```

---

### Task 4: Package and enable Parakeet ASR service

**Files:**
- Create: `pkgs/parakeet-asr/sources.json`
- Create: `pkgs/parakeet-asr/update.sh`
- Create: `pkgs/parakeet-asr/default.nix`
- Create: `dev/ai-stt.nix`
- Modify: `dev/ai.nix` (import `./ai-stt.nix`)
- Modify: `pkgs/overrides.nix` if needed for `callPackage` consistency

**Interfaces:**
- Consumes: achetronic/parakeet Linux amd64 release + ONNX models
- Produces: `parakeet-asr.service` listening `127.0.0.1:10310`, OpenAI `/v1/audio/transcriptions`

- [ ] **Step 1: Create update script + sources (mirror llama-swap pattern)**

`pkgs/parakeet-asr/update.sh`:

```bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix
set -euo pipefail
cd -- "$(dirname "${BASH_SOURCE[0]}")"
META=$(curl -fsSL -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/achetronic/parakeet/releases/latest)
VERSION=$(jq -r '.tag_name' <<<"$META" | sed 's/^v//')
# Pick linux amd64 archive asset name from release (adjust after inspecting assets)
ASSET=$(jq -r '.assets[] | select(.name|test("linux.*amd64|Linux_x86_64")) | .browser_download_url' <<<"$META" | head -n1)
{ read -r hash; read -r _path; } < <(nix-prefetch-url --print-path "$ASSET")
SRI=$(nix-hash --type sha256 --to-sri "$hash")
jq -n --arg v "$VERSION" --arg url "$ASSET" --arg hash "$SRI" \
  '{version:$v, url:$url, hash:$hash}' > sources.json
```

Run it once; if asset naming differs, fix the `jq` filter against the real release assets.

- [ ] **Step 2: Package derivation**

`pkgs/parakeet-asr/default.nix` — `stdenvNoCC` + `autoPatchelfHook` + wrap binary `parakeet` onto PATH; document model dir `/hdd/parakeet`.

- [ ] **Step 3: systemd in `dev/ai-stt.nix`**

```nix
{ pkgs, lib, ... }: {
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/parakeet-asr/default.nix {})
  ];

  systemd.services.parakeet-asr = {
    description = "Parakeet TDT OpenAI-compatible STT (localhost)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "chaton";
      Group = "users";
      ExecStart = ''${pkgs.callPackage ../pkgs/parakeet-asr/default.nix {}}/bin/parakeet -listen 127.0.0.1:10310 -gpu cuda'';
      # If -listen flag name differs, match achetronic/parakeet --help exactly.
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PARAKEET_GPU=cuda"
        "HOME=/home/chaton"
      ];
      # Model path: use flags/env from upstream README (e.g. -models /hdd/parakeet)
      WorkingDirectory = "/hdd/parakeet";
      PrivateTmp = true;
    };
  };
}
```

First boot: create `/hdd/parakeet` and download ONNX models per upstream README (`istupakov/parakeet-tdt-0.6b-v3-onnx`). Prefer a oneshot `parakeet-asr-models.service` or document manual download in README — if oneshot, implement it in this task.

Import from `dev/ai.nix`: `imports = [ ... ./ai-stt.nix ];`

- [ ] **Step 4: Switch + latency smoke test**

```bash
sudo nixos-rebuild switch --flake .#neo-nix
curl -fsS -m 2 http://127.0.0.1:10310/health || curl -fsS http://127.0.0.1:10310/v1/models
# record 3s then:
DICTATION_STT=parakeet dictation-ptt start; sleep 3; time DICTATION_STT=parakeet dictation-ptt stop
```

Expected: service active; `time` real ≤ ~3 s for short clip (excluding human speech). If CUDA EP fails, fall back ExecStart to CPU (`-gpu cpu`) in a follow-up commit in this task and note it.

- [ ] **Step 5: Commit**

```bash
git add pkgs/parakeet-asr dev/ai-stt.nix dev/ai.nix
git commit -m "$(cat <<'EOF'
feat(ai): add local Parakeet OpenAI-compatible STT service

Provide fast FR/EU dictation on localhost:10310 for dictation-ptt.
EOF
)"
```

---

### Task 5: whisper.cpp CUDA secondary backend

**Files:**
- Modify: `dev/ai-stt.nix` (add whisper service)
- Possibly: `pkgs/whisper-cpp-cuda/default.nix` if nixpkgs `whisper-cpp` CUDA override is cleaner than llama-cpp

**Interfaces:**
- Produces: `whisper-cpp-asr.service` on `127.0.0.1:10311` with `/v1/audio/transcriptions` (or whisper.cpp server equivalent path — match upstream flags)

- [ ] **Step 1: Confirm binary API**

```bash
nix-shell -p whisper-cpp --run 'whisper-server -h 2>&1 | head -40' || true
# or from CUDA llama/whisper package
```

Use the server that exposes OpenAI-compatible transcriptions. If only legacy HTTP exists, adapt `openai_transcribe.py` **or** wrap with a tiny proxy — prefer native OpenAI route.

- [ ] **Step 2: Add systemd unit**

Listen `127.0.0.1:10311`, model `ggml-large-v3-turbo.bin` (or `small`) under `/hdd/whisper`, CUDA enabled. Download model once to `/hdd/whisper`.

- [ ] **Step 3: Verify fallback**

```bash
DICTATION_STT=whisper dictation-ptt start; sleep 2; time DICTATION_STT=whisper dictation-ptt stop
# With Parakeet stopped:
sudo systemctl stop parakeet-asr
DICTATION_STT=auto dictation-ptt start; sleep 2; dictation-ptt stop
sudo systemctl start parakeet-asr
```

Expected: whisper path works; auto falls through.

- [ ] **Step 4: Commit**

```bash
git add dev/ai-stt.nix pkgs/whisper-cpp-cuda  # if created
git commit -m "$(cat <<'EOF'
feat(ai): add whisper.cpp CUDA STT fallback for dictation-ptt

Expose localhost:10311 as secondary OpenAI-compatible backend.
EOF
)"
```

---

### Task 6: Docs, attribution, end-to-end acceptance

**Files:**
- Modify: `scripts/ai/dictation-ptt/README.md`
- Modify: `scripts/ai/README.md` (one-line pointer if needed)

- [ ] **Step 1: Update README**

Document:

- Stream Deck press/release
- DMS widget click toggle
- `DICTATION_STT=auto|parakeet|whisper|wyoming`
- Ports 10310 / 10311 / 10300
- Parakeet **CC-BY-4.0** attribution (NVIDIA)
- Latency expectations

- [ ] **Step 2: Acceptance checklist (run and paste results in commit message body or report)**

1. Widget always visible; idle glyph
2. Stream Deck hold → Écoute notif + listening state
3. Release → Transcription notif → paste ≤ 3 s on Parakeet for ~3 s audio
4. Stop Parakeet → auto uses whisper or wyoming
5. Error path still critical notification

- [ ] **Step 3: Commit**

```bash
git add scripts/ai/dictation-ptt/README.md scripts/ai/README.md
git commit -m "$(cat <<'EOF'
docs(ai): document dictation-ptt v2 backends and DMS widget

EOF
)"
```

---

## Self-review vs spec

| Spec requirement | Task |
|------------------|------|
| Notifications start/transcribe/errors + replace-id | Task 1 |
| Always-on indicator; no flicker | Task 2 |
| toggle/status CLI | Task 1 |
| Parakeet default OpenAI HTTP `:10310` | Tasks 3–4 |
| whisper.cpp CUDA `:10311` standalone | Task 5 |
| Wyoming fallback | Task 3 |
| `DICTATION_STT` + auto order | Task 3 |
| localhost only, no new firewall | Tasks 4–5 |
| ≤3 s short clip target | Task 4 acceptance |
| Keep dictation-ptt orchestrator | all |
| CC-BY attribution | Task 6 |
| No Voxtype primary / no wake-agent | omitted |

No TBD placeholders remain; flag names for Parakeet/whisper must be matched to upstream `--help` during Tasks 4–5 (explicit verify step included).
