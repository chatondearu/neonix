#!/usr/bin/env bash
set -euo pipefail

# Args: wav_path silence_ms stop_cmd (path to dictation-ptt)
wav="$1"
silence_ms="$2"
stop_cmd="$3"

poll_ms=200
quiet_ms=0
last_size=0

while [[ ! -s "$wav" ]]; do
  sleep 0.2
done

while true; do
  size="$(stat -c%s "$wav" 2>/dev/null || echo 0)"

  if ((size > last_size)); then
    if ffmpeg -v error -sseof -0.3 -i "$wav" -af "volumedetect" -f null - 2>&1 \
      | awk '/mean_volume:/ { if ($3 + 0 < -40) exit 0; else exit 1 }'; then
      quiet_ms=$((quiet_ms + poll_ms))
    else
      quiet_ms=0
    fi
    last_size=$size
  fi

  if ((quiet_ms >= silence_ms)); then
    exec "$stop_cmd" stop
  fi

  sleep 0.2
done
