#!/usr/bin/env bash
# Session 1 disk prep: GPT + LUKS + LVM + mount at /mnt.
# Formats ONLY the WD_BLACK SN850X (serial 255193400899).
# Run in a real TTY:
#   sudo bash playbooks/scripts/nvme-session1-disk.sh          # full zap
#   sudo bash playbooks/scripts/nvme-session1-disk.sh --resume # LUKS+LVM only (ESP already there)
set -euo pipefail

NEW=/dev/nvme0n1
EXPECT_SERIAL=255193400899
SGDISK=/nix/store/i8l4b5g16lg1y3dmilmb3jj787ia5pkw-gptfdisk-1.0.10/bin/sgdisk

SWAP_G=48
ROOT_G=128
NIX_G=400
RESUME=0
if [[ ${1-} == --resume ]]; then
  RESUME=1
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "Run: sudo bash $0" >&2
  exit 1
fi

if [[ ! -x ${SGDISK} ]]; then
  echo "sgdisk missing at ${SGDISK}" >&2
  exit 1
fi

serial=$(tr -d '[:space:]' </sys/class/block/nvme0n1/device/serial)
model=$(tr -d '[:space:]' </sys/class/block/nvme0n1/device/model)
if [[ ${serial} != "${EXPECT_SERIAL}" ]]; then
  echo "ABORT: ${NEW} serial ${serial} != ${EXPECT_SERIAL}" >&2
  exit 1
fi
if [[ ${model} != *SN850X* ]]; then
  echo "ABORT: ${NEW} model ${model} is not SN850X" >&2
  exit 1
fi

if findmnt "${NEW}" >/dev/null 2>&1 || findmnt "${NEW}p1" >/dev/null 2>&1 || findmnt "${NEW}p2" >/dev/null 2>&1; then
  echo "ABORT: ${NEW} has a mounted filesystem" >&2
  exit 1
fi

for keep in / /boot /games /hdd; do
  src=$(findmnt -no SOURCE "${keep}" || true)
  if [[ ${src} == *nvme0n1* ]]; then
    echo "ABORT: ${keep} is on ${NEW} (${src})" >&2
    exit 1
  fi
done

if [[ -e /dev/mapper/cryptroot ]]; then
  echo "ABORT: /dev/mapper/cryptroot already exists" >&2
  exit 1
fi
if vgs vg0 >/dev/null 2>&1; then
  echo "ABORT: volume group vg0 already exists" >&2
  exit 1
fi

echo "Target ${NEW}  model=${model}  serial=${serial}  resume=${RESUME}"
lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINT "${NEW}"
echo

if [[ ${RESUME} -eq 1 ]]; then
  [[ -b ${NEW}p1 && -b ${NEW}p2 ]] || {
    echo "ABORT: ${NEW}p1/p2 missing; run without --resume" >&2
    exit 1
  }
  if cryptsetup isLuks "${NEW}p2"; then
    echo "ABORT: ${NEW}p2 is already LUKS" >&2
    exit 1
  fi
  echo "Resume: keep existing ESP, LUKS-format p2, then LVM (swap ${SWAP_G}G, root ${ROOT_G}G, nix ${NIX_G}G, home rest)."
  read -r -p "Type CONTINUE to resume: " confirm
  if [[ ${confirm} != CONTINUE ]]; then
    echo "Aborted."
    exit 1
  fi
else
  echo "This will ZAP the WD_BLACK and create ESP + LUKS+LVM (swap ${SWAP_G}G, root ${ROOT_G}G, nix ${NIX_G}G, home rest)."
  read -r -p "Type DESTROY to continue: " confirm
  if [[ ${confirm} != DESTROY ]]; then
    echo "Aborted."
    exit 1
  fi

  "${SGDISK}" --zap-all "${NEW}"
  "${SGDISK}" -n1:0:+2G -t1:EF00 -c1:ESP \
    -n2:0:0 -t2:8309 -c2:cryptroot \
    "${NEW}"
  blockdev --rereadpt "${NEW}" || true
  udevadm settle || true
  sleep 2
  [[ -b ${NEW}p1 && -b ${NEW}p2 ]] || {
    echo "ABORT: partitions ${NEW}p1/p2 did not appear" >&2
    exit 1
  }

  mkfs.fat -F32 -n ESP "${NEW}p1"
fi

echo
echo "LUKS passphrase: the same one you type at every boot (SanDisk). Twice, then once to open."
cryptsetup luksFormat --batch-mode --verify-passphrase "${NEW}p2"
cryptsetup open "${NEW}p2" cryptroot

pvcreate /dev/mapper/cryptroot
vgcreate vg0 /dev/mapper/cryptroot
lvcreate -L ${SWAP_G}G -n swap vg0
lvcreate -L ${ROOT_G}G -n root vg0
lvcreate -L ${NIX_G}G -n nix vg0
lvcreate -l 100%FREE -n home vg0

mkswap -L swap /dev/vg0/swap
mkfs.ext4 -L nixos /dev/vg0/root
mkfs.ext4 -L nix /dev/vg0/nix
mkfs.ext4 -L home /dev/vg0/home

mount /dev/vg0/root /mnt
mkdir -p /mnt/{boot,home,nix}
mount "${NEW}p1" /mnt/boot
mount /dev/vg0/home /mnt/home
mount /dev/vg0/nix /mnt/nix

echo
echo "=== DONE disk prep ==="
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "${NEW}"
lvs -o lv_name,vg_name,lv_size
findmnt /mnt /mnt/boot /mnt/home /mnt/nix
echo
echo "Tell the agent: disk prep done."
