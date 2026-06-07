# raspberry/ — odio hardware validation (Pi Zero W / WH)

Nix environment to flash an **odio armhf** image and apply the **Merus AMP** overlay (InnoMaker MA12070P).

Current target hardware: **Raspberry Pi Zero W / WH** (32-bit).  
The NixOS [`pi-sound`](../nixos/hosts/pi-sound/) project is still tuned for **Pi Zero 2 W** — adaptation planned later.

**Phase 1**: boot + I2S Merus on Zero W.  
**Phase 2**: USB input → speakers — see [`odio/usb-input.md`](odio/usb-input.md).

## Prerequisites

- SD card + USB reader
- **Pi Zero W / WH** + InnoMaker MA12070P HAT (external amp PSU if required)
- **5 V / 2 A** PSU minimum (Zero W + amp is power-hungry)
- `direnv` (optional) or `nix develop`

> **Do not** flash **odio arm64** on a Zero W — firmware blinks **7 times** (kernel not found).

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

By default: **odio (armhf)** + cloud-init from `odio/.env` + Merus overlay.  
Hidden network: `WIFI_HIDDEN=true` in `.env`.  
Regulatory domain: `WIFI_COUNTRY=FR` (defaults to FR if omitted).

Options:

- `--skip-merus` — flash odio only
- `--arm64` — Pi Zero **2 W** / Pi 3+ (not Zero W)

## Shell tools

| Command | Role |
|---------|------|
| `flash-odio-cli /dev/sdX` | odio **armhf** + Merus (**Zero W/WH**) |
| `flash-odio-cli /dev/sdX --arm64` | odio arm64 (Zero 2 W / Pi 3+) |
| `apply-merus-config /dev/sdX` | Merus only, after manual flash |
| `deploy-usb-route odio@host --install` | Phase 2: USB line-in → Merus (SSH) |
| `rpi-imager-odio` | GUI Imager + manifest reminder |

## Phase 2 — USB → Merus

After phase 1 is validated, connect the UCA202 and run:

```bash
deploy-usb-route odio@pi-odio.local --status
deploy-usb-route odio@pi-odio.local --install
```

Details: [`odio/usb-input.md`](odio/usb-input.md).

## Interpretation

| Result | Conclusion |
|--------|------------|
| odio + Merus OK, NixOS fails | Nix pi-sound stack issue (Zero 2 W), not the HAT |
| 7 LED flashes | arm64 on Zero W, or wrong SD / image |
| Boot OK, no `sndrpimerusamp` | HAT, overlay, amp PSU |
