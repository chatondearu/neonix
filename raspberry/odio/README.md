# odio — Pi Zero W / WH + Merus AMP (phase 1)

Validation matérielle avec une image [odio](https://odio.love/) **armhf** sur **Raspberry Pi Zero W / WH**.

Le NixOS [`pi-sound`](../../nixos/hosts/pi-sound/) vise un **Pi Zero 2 W** — on l’alignera sur ce matériel dans un second temps.

## Matériel

- Raspberry Pi **Zero W** ou **Zero WH**
- InnoMaker MA12070P (overlay `merus-amp`, ALSA `sndrpimerusamp`)

## Flash (CLI)

```bash
cd raspberry
cp odio/.env.example odio/.env   # HOSTNAME, ODIO_IMAGE, WIFI_*, WIFI_HIDDEN, SSH
nix develop
flash-odio-cli /dev/sdX
```

Lit `odio/.env` depuis **ton dépôt** (`raspberry/odio/.env`), pas le store Nix.

| Option | Usage |
|--------|--------|
| (défaut) | odio **armhf** — Pi Zero W / WH |
| `--arm64` | Pi Zero **2 W**, Pi 3/4/5 uniquement |
| `--skip-merus` | Pas de fusion `config.txt` |

Réseau Wi‑Fi caché : `WIFI_HIDDEN=true` dans `odio/.env` (netplan `hidden: true`).

## Pi Zero W vs Zero 2 W

| Carte | Image odio |
|-------|------------|
| Zero W / WH | **armhf** (`odio (armhf)`) |
| Zero 2 W | arm64 (`--arm64`) |

arm64 sur un Zero W → **7 clignotements** LED (kernel introuvable).

## Flash (GUI)

Manifest : `https://beta.odio.love/odio.rpi-imager-manifest`  
Choisir **odio (armhf)**, puis :

```bash
apply-merus-config /dev/sdX
```

## Merus overlay

Le script fusionne [`config.txt`](config.txt) sur la partition boot (overlay `merus-amp` — HAT prévu pour le Zero W).

Option PBTL :

```ini
gpio=8=op,dl
```

## Tests sur le Pi

```bash
ssh odio@<hostname>.local
aplay -l
speaker-test -D hw:sndrpimerusamp,0 -c 2 -t wav
```

| Test | Attendu | Si échec |
|------|---------|----------|
| Boot + SSH | Shell | SD, alim 2 A+, Wi‑Fi |
| `aplay -l` | `sndrpimerusamp` | HAT, overlay, alim amp |
| `speaker-test` | Son HP | câblage, PBTL |

## Suite

- Entrée USB : [`TODO-usb-input.md`](TODO-usb-input.md)
- pi-sound NixOS pour Zero 2 W : à venir
