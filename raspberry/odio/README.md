# odio — Pi Zero 2 W + Merus AMP (phase 1)

Validation matérielle avec une image [odio](https://odio.love/) arm64 avant de revenir sur le build NixOS `pi-sound`.

Matériel cible :

- Raspberry Pi Zero 2 W
- InnoMaker MA12070P (overlay `merus-amp`, ALSA `sndrpimerusamp`)

## Flash (CLI — recommandé)

```bash
cd raspberry
cp odio/.env.example odio/.env   # puis éditer
nix develop
flash-odio-cli /dev/sdX
```

Lit `odio/.env` depuis **ton dépôt** (`raspberry/odio/.env`), pas le store Nix. Lance la commande depuis `raspberry/` (`nix develop` ou direnv).

Options : `--skip-merus` pour ne pas fusionner `config.txt`.

## Flash (GUI)

`rpi-imager-odio` + manifest `https://beta.odio.love/odio.rpi-imager-manifest`, puis :

```bash
apply-merus-config /dev/sdX
```

Le script :

- Monte la partition boot (p1)
- Sauvegarde `config.txt` (ou `firmware/config.txt`)
- Fusionne le fragment [`config.txt`](config.txt) (aligné sur `pi-sound`)

Option PBTL (si amp câblé ainsi) — ajouter manuellement sur le Pi ou dans le fragment :

```ini
gpio=8=op,dl
```

## Tests sur le Pi

```bash
ssh odio@<hostname>.local
aplay -l                    # expect: card … sndrpimerusamp
speaker-test -D hw:sndrpimerusamp,0 -c 2 -t wav
```

| Test | Attendu | Si échec |
|------|---------|----------|
| Boot + SSH | Accès shell | SD, alim 2.5 A, Wi‑Fi |
| `aplay -l` | `sndrpimerusamp` | HAT, overlay, alim amp |
| `speaker-test` | Son sur enceintes | HP, amp, PBTL |
| UI odio (optionnel) | `http://<ip>:8018/ui` | Stack odio (hors HW Merus) |

## Suite : entrée USB

Reportée — prototype manuel en SSH documenté dans [`TODO-usb-input.md`](TODO-usb-input.md).
