# odio — Pi Zero W / WH + Merus AMP (phase 1)

Hardware validation with an **armhf** [odio](https://odio.love/) image on **Raspberry Pi Zero W / WH**.

NixOS [`pi-sound`](../../nixos/hosts/pi-sound/) targets a **Pi Zero 2 W** — alignment with this hardware will come later.

## Hardware

- Raspberry Pi **Zero W** or **Zero WH**
- InnoMaker MA12070P (`merus-amp` overlay, ALSA `sndrpimerusamp`)

## Flash (CLI)

```bash
cd raspberry
cp odio/.env.example odio/.env   # HOSTNAME, ODIO_IMAGE, WIFI_*, WIFI_HIDDEN, SSH
nix develop
flash-odio-cli /dev/sdX
```

Reads `odio/.env` from **your checkout** (`raspberry/odio/.env`), not the Nix store.

| Option | Usage |
|--------|--------|
| (default) | odio **armhf** — Pi Zero W / WH |
| `--arm64` | Pi Zero **2 W**, Pi 3/4/5 only |
| `--skip-merus` | Skip `config.txt` merge |

Hidden Wi‑Fi: `WIFI_HIDDEN=true` in `odio/.env` (netplan `hidden: true`).  
Regulatory domain: `WIFI_COUNTRY=FR` (default **FR** — required for headless Wi‑Fi).

## Pi Zero W vs Zero 2 W

| Board | odio image |
|-------|------------|
| Zero W / WH | **armhf** (`odio (armhf)`) |
| Zero 2 W | arm64 (`--arm64`) |

arm64 on a Zero W → **7 LED flashes** (kernel not found).

## Flash (GUI)

Manifest: `https://beta.odio.love/odio.rpi-imager-manifest`  
Select **odio (armhf)**, then:

```bash
apply-merus-config /dev/sdX
```

## Merus overlay

The script merges [`config.txt`](config.txt) onto the boot partition (`merus-amp` overlay — HAT designed for Zero W).

PBTL option:

```ini
gpio=8=op,dl
```

## Tests on the Pi

```bash
ssh odio@<hostname>.local
aplay -l
speaker-test -D hw:sndrpimerusamp,0 -c 2 -t wav
```

| Test | Expected | On failure |
|------|----------|------------|
| Boot + SSH | Shell | SD, 2 A+ PSU, Wi‑Fi |
| `aplay -l` | `sndrpimerusamp` | HAT, overlay, amp PSU |
| `speaker-test` | Speaker sound | wiring, PBTL |

## Phase 2 — USB line-in → Merus

From the dev machine (UCA202 codec connected to the Pi):

```bash
deploy-usb-route odio@<hostname>.local --status
deploy-usb-route odio@<hostname>.local --install
```

Full docs: [`usb-input.md`](usb-input.md).

## Next steps

- pi-sound NixOS for Zero 2 W: coming soon
