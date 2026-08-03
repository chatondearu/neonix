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
