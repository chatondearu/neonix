# raspberry/ — validation matérielle odio (Pi Zero 2 W)

Environnement Nix pour flasher une image **odio arm64** et appliquer l'overlay **Merus AMP** (InnoMaker MA12070P), en parallèle du projet NixOS [`pi-sound`](../nixos/hosts/pi-sound/).

**Phase 1** (ce dossier) : boot + I2S Merus.  
**Phase 2** (reportée) : entrée USB → enceintes — voir [`odio/TODO-usb-input.md`](odio/TODO-usb-input.md).

## Prérequis

- Carte SD + lecteur USB
- Pi Zero 2 W + HAT InnoMaker MA12070P (alim amp externe si requis)
- `direnv` (optionnel) ou `nix develop`

## Setup

```bash
cd raspberry
direnv allow   # or: nix develop
```

## Workflow (recommandé : CLI)

1. Copier et remplir la config :

   ```bash
   cp odio/.env.example odio/.env   # HOSTNAME, WIFI_*, SSH_PUBLIC_KEY
   ```

2. **Flasher odio + Merus en une commande** (sudo pour l’écriture sur la SD) :

   ```bash
   flash-odio-cli /dev/sdX
   ```

   Remplace `sdX` par le périphérique SD (pas `/dev/sda` ni NVMe système).

3. **Boot et tests** — détail dans [`odio/README.md`](odio/README.md)

### Alternative GUI

Si Polkit / l’affichage posent problème, préférer le CLI ci-dessus.

```bash
rpi-imager-odio   # puis apply-merus-config /dev/sdX
```

## Outils du shell

| Commande | Rôle |
|----------|------|
| `flash-odio-cli /dev/sdX` | Flash odio arm64 (`.env`) + overlay Merus (**recommandé**) |
| `apply-merus-config /dev/sdX` | Merus seulement, après flash manuel |
| `rpi-imager-odio` | GUI Imager + rappel manifest |
| `rpi-imager` | Imager nu |

## Interprétation

| Résultat | Conclusion |
|----------|------------|
| odio + Merus OK, NixOS KO | Problème stack Nix / image SD, pas le HAT |
| odio KO au boot | SD, alimentation, Wi‑Fi |
| Boot OK, pas de `sndrpimerusamp` | HAT, overlay, câblage I2S |
