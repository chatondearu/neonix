# raspberry/ — validation matérielle odio (Pi Zero W / WH)

Environnement Nix pour flasher une image **odio armhf** et appliquer l'overlay **Merus AMP** (InnoMaker MA12070P).

Matériel cible actuel : **Raspberry Pi Zero W / WH** (32-bit).  
Le projet NixOS [`pi-sound`](../nixos/hosts/pi-sound/) reste calibré **Pi Zero 2 W** — adaptation prévue plus tard.

**Phase 1** (ce dossier) : boot + I2S Merus sur Zero W.  
**Phase 2** (reportée) : entrée USB → enceintes — voir [`odio/TODO-usb-input.md`](odio/TODO-usb-input.md).

## Prérequis

- Carte SD + lecteur USB
- **Pi Zero W / WH** + HAT InnoMaker MA12070P (alim amp externe si requis)
- Alim **5 V / 2 A** minimum (Zero W + amp = gourmand)
- `direnv` (optionnel) ou `nix develop`

> **Ne pas** flasher **odio arm64** sur un Zero W — le firmware clignote **7 fois** (kernel introuvable).

## Setup

```bash
cd raspberry
direnv allow   # or: nix develop
cp odio/.env.example odio/.env
```

## Workflow (CLI)

```bash
flash-odio-cli /dev/sdX
```

Par défaut : **odio (armhf)** + cloud-init depuis `odio/.env` + overlay Merus.  
Réseau caché : `WIFI_HIDDEN=true` dans `.env`.

Options :

- `--skip-merus` — flash odio seulement
- `--arm64` — Pi Zero **2 W** / Pi 3+ (pas Zero W)

## Outils du shell

| Commande | Rôle |
|----------|------|
| `flash-odio-cli /dev/sdX` | odio **armhf** + Merus (**Zero W/WH**) |
| `flash-odio-cli /dev/sdX --arm64` | odio arm64 (Zero 2 W / Pi 3+) |
| `apply-merus-config /dev/sdX` | Merus seulement, après flash manuel |
| `rpi-imager-odio` | GUI Imager + rappel manifest |

## Interprétation

| Résultat | Conclusion |
|----------|------------|
| odio + Merus OK, NixOS KO | Problème stack Nix pi-sound (Zero 2 W), pas le HAT |
| 7 flashs LED | arm64 sur Zero W, ou SD / image incorrecte |
| Boot OK, pas de `sndrpimerusamp` | HAT, overlay, alim amp |
