#!/usr/bin/env bash
# Flash odio via rpi-imager CLI, then apply Merus boot config.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$SCRIPT_DIR"
# shellcheck source=lib.sh
source "${BUNDLE_DIR}/lib.sh"

CONFIG_DIR=""
if ! CONFIG_DIR="$(resolve_odio_config_dir)"; then
  echo "Missing odio/.env in your checkout." >&2
  echo "  cd raspberry && cp odio/.env.example odio/.env" >&2
  echo "  Or set RASPBERRY_ODIO_DIR to the directory containing .env" >&2
  exit 1
fi

ENV_FILE="${CONFIG_DIR}/.env"
if [ -f "${CONFIG_DIR}/manifest.url" ]; then
  MANIFEST_URL="$(tr -d '[:space:]' <"${CONFIG_DIR}/manifest.url")"
else
  MANIFEST_URL="$(tr -d '[:space:]' <"${BUNDLE_DIR}/manifest.url")"
fi

TARGET_DEV=""
SKIP_MERUS=false
CLI_ODIO_IMAGE=""
TMP_DIR=""
USER_DATA=""
NETWORK_CONFIG=""

cleanup() {
  [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: flash-odio-cli.sh /dev/sdX [--armhf | --arm64] [--skip-merus]

Flashes odio from the official manifest using rpi-imager --cli
(Wi-Fi / SSH / hostname from odio/.env), then merges Merus AMP boot config.

Default image: odio (armhf) for Raspberry Pi Zero W / WH.
Use --arm64 for Pi Zero 2 W, Pi 3/4/5 (not Pi Zero W — causes 7 LED flashes).

Requires: odio/.env (copy from .env.example), sudo for block device write.
EOF
}

blocked_device() {
  case "$1" in
    /dev/sda | /dev/nvme0n1 | /dev/nvme1n1) return 0 ;;
    *) return 1 ;;
  esac
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --skip-merus)
      SKIP_MERUS=true
      ;;
    --armhf)
      CLI_ODIO_IMAGE="armhf"
      ;;
    --arm64)
      CLI_ODIO_IMAGE="arm64"
      ;;
    *)
      if [ -n "$TARGET_DEV" ]; then
        echo "Unexpected argument: $arg" >&2
        usage >&2
        exit 1
      fi
      TARGET_DEV="$arg"
      ;;
  esac
done

if [ -z "$TARGET_DEV" ]; then
  usage >&2
  exit 1
fi

if blocked_device "$TARGET_DEV"; then
  echo "Refused: $TARGET_DEV looks like a system disk." >&2
  exit 1
fi

if [ ! -b "$TARGET_DEV" ]; then
  echo "Not a block device: $TARGET_DEV" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE (copy from .env.example)." >&2
  echo "  Expected under: ${CONFIG_DIR}/" >&2
  exit 1
fi

if ! command -v rpi-imager >/dev/null; then
  echo "rpi-imager not in PATH — run from: cd raspberry && nix develop" >&2
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "jq not in PATH — run from: cd raspberry && nix develop" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

if [ -n "$CLI_ODIO_IMAGE" ]; then
  ODIO_IMAGE="$CLI_ODIO_IMAGE"
else
  ODIO_IMAGE="${ODIO_IMAGE:-armhf}"
fi

case "$ODIO_IMAGE" in
  armhf) ODIO_MANIFEST_NAME="odio (armhf)" ;;
  arm64) ODIO_MANIFEST_NAME="odio (arm64)" ;;
  *)
    echo "Invalid ODIO_IMAGE: $ODIO_IMAGE (use armhf or arm64)" >&2
    exit 1
    ;;
esac

: "${HOSTNAME:?HOSTNAME required in .env}"
: "${SSH_PUBLIC_KEY:?SSH_PUBLIC_KEY required in .env}"

TMP_DIR="$(mktemp -d)"
USER_DATA="${TMP_DIR}/user-data"
NETWORK_CONFIG="${TMP_DIR}/network-config"

cat >"$USER_DATA" <<EOF
#cloud-config
hostname: ${HOSTNAME}
manage_etc_hosts: true
ssh_pwauth: false
enable_ssh: true
users:
  - name: odio
    gecos: odio streamer
    groups: [adm, audio, cdrom, dialout, dip, gpio, i2c, input, netdev, plugdev, render, spi, sudo, video]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - ${SSH_PUBLIC_KEY}
EOF

if [ -n "${WIFI_SSID:-}" ] && [ -n "${WIFI_PSK:-}" ]; then
  WIFI_HIDDEN_LINE=""
  case "${WIFI_HIDDEN:-false}" in
    true | 1 | yes | YES | True) WIFI_HIDDEN_LINE="        hidden: true" ;;
  esac
  cat >"$NETWORK_CONFIG" <<EOF
version: 2
wifis:
  wlan0:
    dhcp4: true
    optional: true
    access-points:
      "${WIFI_SSID}":
        password: "${WIFI_PSK}"
${WIFI_HIDDEN_LINE}
EOF
else
  NETWORK_CONFIG=""
  echo "Note: WIFI_SSID/WIFI_PSK not set — flash without Wi-Fi cloud-init."
fi

echo "[1/3] Resolving ${ODIO_MANIFEST_NAME} from manifest..."
MANIFEST="$(curl -fsSL "$MANIFEST_URL")"
IMAGE_URL="$(echo "$MANIFEST" | jq -r --arg name "$ODIO_MANIFEST_NAME" '.os_list[] | select(.name == $name) | .url')"
# rpi-imager --sha256 verifies the decompressed .img, not the .xz download
IMAGE_SHA256="$(echo "$MANIFEST" | jq -r --arg name "$ODIO_MANIFEST_NAME" '.os_list[] | select(.name == $name) | .extract_sha256')"

if [ -z "$IMAGE_URL" ] || [ "$IMAGE_URL" = "null" ]; then
  echo "Could not find ${ODIO_MANIFEST_NAME} in manifest." >&2
  exit 1
fi

echo "      Image: ${ODIO_MANIFEST_NAME}"
echo "      URL: $IMAGE_URL"
echo "      SHA256 (extracted .img): $IMAGE_SHA256"

if [ "$ODIO_IMAGE" = "arm64" ]; then
  echo "      Warning: arm64 will not boot on Pi Zero W/WH (7 LED flashes)."
fi

echo "[2/3] Flashing to $TARGET_DEV (sudo, rpi-imager --cli)..."
sudo umount "${TARGET_DEV}"* 2>/dev/null || true

IMAGER="$(command -v rpi-imager)"
FLASH_CMD=(sudo env "PATH=$PATH" "$IMAGER" --cli --sha256 "$IMAGE_SHA256" --cloudinit-userdata "$USER_DATA")

if [ -n "$NETWORK_CONFIG" ]; then
  FLASH_CMD+=(--cloudinit-networkconfig "$NETWORK_CONFIG")
fi

FLASH_CMD+=("$IMAGE_URL" "$TARGET_DEV")

"${FLASH_CMD[@]}"

if [ "$SKIP_MERUS" = true ]; then
  echo "Skipping Merus config (--skip-merus)."
  exit 0
fi

echo "[3/3] Applying Merus AMP boot overlay..."
"${BUNDLE_DIR}/apply-merus-config.sh" "$TARGET_DEV"

cat <<EOF

OK. SD ready (${ODIO_MANIFEST_NAME}, Pi Zero W/WH).

  ssh odio@${HOSTNAME}.local
  aplay -l
  speaker-test -D hw:sndrpimerusamp,0 -c 2 -t wav
EOF
