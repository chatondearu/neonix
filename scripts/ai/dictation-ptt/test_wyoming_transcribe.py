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
