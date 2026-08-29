#!/usr/bin/env bash
# Stub: regenerate niri dms/binds.kdl from dictation-ptt config (Task 5 fleshes this out).
set -euo pipefail

CFG="${DICTATION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dictation-ptt/config.json}"
OUT="${NIRI_DMS_BINDS:-${XDG_CONFIG_HOME:-$HOME/.config}/niri/dms/binds.kdl}"

# TODO(Task 5): read mode + keyboard_key from $CFG and write hold/toggle binds to $OUT.
# Do not overwrite an existing binds file from this stub.
mkdir -p "$(dirname "$OUT")"
: "${CFG}" # referenced so Task 5 wiring is clear; unused in stub

exit 0
