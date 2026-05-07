#!/usr/bin/env bash
set -euo pipefail

TARGET_DEV="${1:-}"

if [ -z "$TARGET_DEV" ]; then
  echo "Usage: $0 /dev/sdX"
  exit 1
fi

# Prévention d'écrasement basique (à ajuster selon ton système)
if [[ "$TARGET_DEV" == "/dev/sda" || "$TARGET_DEV" == "/dev/nvme0n1" ]]; then
  echo "Protection de sécurité : Périphérique cible ignoré."
  exit 1
fi

if [ -f .env ]; then
  # set -a exporte automatiquement toutes les variables sourcées
  set -a
  source .env
  set +a
else
  echo "Erreur: fichier .env introuvable."
  exit 1
fi

echo "[1/3] Compilation de l'image SD (ARMv7)..."
nix build .#packages.armv7l-linux.sdImage --impure

IMG=$(find result/sd-image -name "*.img" -type f | head -n 1)

if [ -z "$IMG" ]; then
  echo "Erreur critique : Image .img introuvable dans result/sd-image/"
  exit 1
fi

echo "[2/3] Démontage des partitions éventuelles de $TARGET_DEV..."
sudo umount "${TARGET_DEV}"* || true

echo "[3/3] Flashage de $IMG sur $TARGET_DEV..."
sudo dd if="$IMG" of="$TARGET_DEV" bs=4M status=progress
sudo sync

echo "Succès. Retirer la carte SD."