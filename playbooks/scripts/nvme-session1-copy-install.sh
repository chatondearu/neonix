#!/usr/bin/env bash
# Session 1: rsync SanDisk -> /mnt (vg0) then nixos-install Limine on the new ESP.
# Run in a real TTY after the flake points at vg0:
#   sudo bash playbooks/scripts/nvme-session1-copy-install.sh
set -euo pipefail

NEW=/dev/nvme0n1
EXPECT_SERIAL=255193400899
FLAKE=/home/chaton/etc/nixos

if [[ ${EUID} -ne 0 ]]; then
  echo "Run: sudo bash $0" >&2
  exit 1
fi

serial=$(tr -d '[:space:]' </sys/class/block/nvme0n1/device/serial)
if [[ ${serial} != "${EXPECT_SERIAL}" ]]; then
  echo "ABORT: ${NEW} serial ${serial} != ${EXPECT_SERIAL}" >&2
  exit 1
fi

root_src=$(findmnt -no SOURCE /)
if [[ ${root_src} != *luks-97c4ccff* ]]; then
  echo "ABORT: live / is ${root_src}, expected SanDisk LUKS" >&2
  exit 1
fi

mnt_src=$(findmnt -no SOURCE /mnt)
if [[ ${mnt_src} != /dev/mapper/vg0-root ]]; then
  echo "ABORT: /mnt is ${mnt_src}, expected /dev/mapper/vg0-root" >&2
  exit 1
fi
for p in /mnt/boot /mnt/home /mnt/nix; do
  if ! findmnt "${p}" >/dev/null; then
    echo "ABORT: ${p} is not mounted" >&2
    exit 1
  fi
done

echo "Live root: ${root_src}"
echo "Target:    ${mnt_src} on WD_BLACK ${serial}"
echo "Copy ~284G then nixos-install. Do not nixos-rebuild switch."
echo

systemctl stop nix-daemon || true

rsync -aAXh --info=progress2 --numeric-ids \
  --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*' \
  --exclude='/tmp/*' --exclude='/run/*' --exclude='/mnt/*' \
  --exclude='/media/*' --exclude='/lost+found' \
  --exclude='/boot/*' --exclude='/home/*' --exclude='/nix/*' \
  --exclude='/hdd/*' --exclude='/games/*' \
  / /mnt/

rsync -aAXh --info=progress2 --numeric-ids /home/ /mnt/home/
rsync -aAXh --info=progress2 --numeric-ids /nix/ /mnt/nix/
rsync -aAXh --info=progress2 --numeric-ids /boot/ /mnt/boot/

systemctl start nix-daemon || true

rsync -aAXh "${FLAKE}/" /mnt/home/chaton/etc/nixos/

echo
echo "=== copy done, installing bootloader ==="
nixos-install --root /mnt --flake "${FLAKE}#neo-nix" --no-root-passwd

echo
echo "=== DONE copy+install ==="
for p in / /mnt /mnt/boot /mnt/home /mnt/nix; do findmnt "${p}" || true; done
ls /mnt/boot | head
echo
echo "Live / must still be the SanDisk mapper."
echo "Tell the agent: copy+install done. Then reboot to UEFI and boot the WD_BLACK."
