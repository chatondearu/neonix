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
