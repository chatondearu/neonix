#!/usr/bin/env bash
# Copy install-usb-route.sh to the Pi and run it over SSH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install-usb-route.sh"

usage() {
  cat <<'EOF'
Usage: deploy-usb-route.sh user@host [--install | --remove | --status | --test-alsaloop]

Deploys odio/install-usb-route.sh to the Pi and executes it.

Examples:
  deploy-usb-route.sh odio@pi-odio.local --status
  deploy-usb-route.sh odio@pi-odio.local --install
  deploy-usb-route.sh odio@pi-odio.local --remove

Environment (forwarded to remote install script):
  USB_ALSA_ID, MERUS_ALSA_CARD, LOOPBACK_LATENCY_MS
  USB_SOURCE_PATTERN, MERUS_SINK_PATTERN
EOF
}

if [ $# -lt 1 ]; then
  usage >&2
  exit 1
fi

HOST="$1"
shift

if [ ! -f "$INSTALL_SCRIPT" ]; then
  echo "Missing $INSTALL_SCRIPT" >&2
  exit 1
fi

REMOTE="/tmp/install-usb-route-$$.sh"
REMOTE_ARGS=("$@")
if [ ${#REMOTE_ARGS[@]} -eq 0 ]; then
  REMOTE_ARGS=(--install)
fi

echo "Copying install script to ${HOST}..."
scp -q "$INSTALL_SCRIPT" "${HOST}:${REMOTE}"

echo "Running on ${HOST}: install-usb-route.sh ${REMOTE_ARGS[*]}"
ssh -t "$HOST" \
  "USB_ALSA_ID=${USB_ALSA_ID:-CODEC} \
   MERUS_ALSA_CARD=${MERUS_ALSA_CARD:-sndrpimerusamp} \
   LOOPBACK_LATENCY_MS=${LOOPBACK_LATENCY_MS:-50} \
   USB_SOURCE_PATTERN=${USB_SOURCE_PATTERN:-} \
   MERUS_SINK_PATTERN=${MERUS_SINK_PATTERN:-} \
   MERUS_PA_SINK_NAME=${MERUS_PA_SINK_NAME:-merus_amp} \
   chmod +x '${REMOTE}' && bash '${REMOTE}' ${REMOTE_ARGS[*]}; rc=\$?; rm -f '${REMOTE}'; exit \$rc"
