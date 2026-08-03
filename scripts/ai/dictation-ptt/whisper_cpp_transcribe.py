#!/usr/bin/env python3
"""POST a WAV to whisper.cpp server /inference endpoint."""

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
    language: str | None = "fr",
    timeout: float = 60.0,
) -> str:
    url = base_url.rstrip("/") + "/inference"
    data: dict[str, str] = {"response_format": "json"}
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
    p.add_argument("--language", default="fr")
    p.add_argument("--timeout", type=float, default=60.0)
    args = p.parse_args()
    try:
        text = transcribe_file(
            args.wav,
            args.base_url,
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
