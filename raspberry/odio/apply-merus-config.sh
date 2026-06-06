#!/usr/bin/env bash
# Merge Merus AMP boot config into an odio SD card (boot partition only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAGMENT="${SCRIPT_DIR}/config.txt"
MOUNT_POINT=""
TARGET_DEV=""

cleanup() {
  if [ -n "$MOUNT_POINT" ] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    sudo umount "$MOUNT_POINT" || true
  fi
  if [ -n "$MOUNT_POINT" ]; then
    rmdir "$MOUNT_POINT" 2>/dev/null || true
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: apply-merus-config.sh /dev/sdX

After flashing an odio image, merges Merus AMP settings from
odio/config.txt into the SD boot partition (config.txt or firmware/config.txt).

Requires sudo to mount the boot partition.
EOF
}

blocked_device() {
  case "$1" in
    /dev/sda | /dev/nvme0n1 | /dev/nvme1n1) return 0 ;;
    *) return 1 ;;
  esac
}

merge_fragment() {
  local config_file="$1"
  local tmp merged line
  tmp="$(mktemp)"
  merged="$(mktemp)"

  cp "$config_file" "$tmp"

  # Drop stale Merus-related lines before applying the fragment.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      dtparam=audio=* | dtparam=i2s=* | dtoverlay=merus-amp* \
        | disable_fw_kms_setup=* | camera_auto_detect=* \
        | display_auto_detect=* | max_framebuffers=*)
        continue
        ;;
      *)
        printf '%s\n' "$line" >>"$merged"
        ;;
    esac
  done <"$tmp"

  # Ensure audio=off even if the image had audio=on without a matching line above.
  sed -i '/^dtparam=audio=on$/d' "$merged"

  if [ -s "$FRAGMENT" ]; then
    printf '\n# --- Merus AMP (apply-merus-config) ---\n' >>"$merged"
    cat "$FRAGMENT" >>"$merged"
  fi

  cp "$merged" "$config_file"
  rm -f "$tmp" "$merged"
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
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

if [ ! -f "$FRAGMENT" ]; then
  echo "Missing fragment: $FRAGMENT" >&2
  exit 1
fi

BOOT_PART="${TARGET_DEV}1"
if [ ! -b "$BOOT_PART" ]; then
  echo "Boot partition not found: $BOOT_PART" >&2
  exit 1
fi

echo "Unmounting ${TARGET_DEV}* ..."
sudo umount "${TARGET_DEV}"* 2>/dev/null || true

MOUNT_POINT="$(mktemp -d)"
echo "Mounting $BOOT_PART on $MOUNT_POINT ..."
sudo mount "$BOOT_PART" "$MOUNT_POINT"

CONFIG=""
if [ -f "$MOUNT_POINT/firmware/config.txt" ]; then
  CONFIG="$MOUNT_POINT/firmware/config.txt"
elif [ -f "$MOUNT_POINT/config.txt" ]; then
  CONFIG="$MOUNT_POINT/config.txt"
else
  echo "No config.txt found on boot partition." >&2
  exit 1
fi

BACKUP="${CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
echo "Backing up to $(basename "$BACKUP") ..."
sudo cp "$CONFIG" "$BACKUP"

WORK="$(mktemp)"
sudo cp "$CONFIG" "$WORK"
sudo chown "$(id -u):$(id -g)" "$WORK"

echo "Merging Merus AMP fragment into $CONFIG ..."
merge_fragment "$WORK"
sudo cp "$WORK" "$CONFIG"
rm -f "$WORK"

sudo sync
echo "Done. Merus config applied on $(basename "$BOOT_PART")."
