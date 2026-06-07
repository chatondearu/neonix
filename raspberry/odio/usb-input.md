# Phase 2 — USB input → Merus speakers

Route **USB line-in** (Behringer UCA202/UCA222, ALSA card `CODEC`) to the **Merus** (`sndrpimerusamp`) on odio, **without breaking** AirPlay / Spotify / Bluetooth.

## Approach

| Stack | pi-sound (NixOS) | odio (phase 2) |
|-------|------------------|----------------|
| Audio server | Pure ALSA | PulseAudio (odio) |
| USB → Merus | `alsaloop` systemd | PulseAudio `module-loopback` |
| Streaming coexistence | N/A | Yes |

pi-sound reference: `options snd-usb-audio index=1`, card `CODEC`, `alsaloop -C usbcodec -P merus -t 50000` (50 ms).

## Prerequisites

- Phase 1 OK: `speaker-test -D hw:sndrpimerusamp,0 -c 2 -t wav`
- USB codec connected (OTG on Zero W if needed)
- SSH: `ssh odio@<hostname>.local`

## Deploy from the dev machine

```bash
cd raspberry
nix develop

# Diagnostics (does not modify the Pi)
deploy-usb-route odio@pi-odio.local --status

# Install route + persistence at login
deploy-usb-route odio@pi-odio.local --install
```

Connect the PC **line-in** to the UCA202 — audio should play through the Merus speakers.

## Commands on the Pi (SSH)

Copy the script from the repo or use `deploy-usb-route` from the dev machine.

```bash
bash install-usb-route.sh --status
bash install-usb-route.sh --install
bash install-usb-route.sh --remove
```

Use **`bash`**, not `sh` (the script requires bash).

## Environment variables

| Variable | Default | Role |
|----------|---------|------|
| `USB_ALSA_ID` | `CODEC` | ALSA id for UCA202/UCA222 |
| `MERUS_ALSA_CARD` | `sndrpimerusamp` | Merus card |
| `LOOPBACK_LATENCY_MS` | `50` | PulseAudio loopback latency |
| `USB_SOURCE_PATTERN` | (auto) | Override PA source detection |
| `MERUS_SINK_PATTERN` | (auto) | Override PA sink detection |
| `MERUS_PA_SINK_NAME` | `merus_amp` | Sink name when loading `module-alsa-sink` |

Higher latency example:

```bash
LOOPBACK_LATENCY_MS=80 deploy-usb-route odio@pi-odio.local --install
```

## Hardware diagnostic (alsaloop)

For isolating a USB issue **without** PulseAudio only:

```bash
install-usb-route.sh --test-alsaloop
# Ctrl+C then:
systemctl --user start pulseaudio
```

Guaranteed conflict with odio if both run in parallel.

## Validation checklist

- [ ] `arecord -l` → card `CODEC`
- [ ] `pactl list short sinks` → Merus sink (`merus_amp` or `sndrpimerusamp`)
- [ ] `--install` → line-in signal audible on Merus
- [ ] Acceptable latency (~50 ms)
- [ ] AirPlay or Spotify still works with the route active

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| USB source not found | Replug UCA202; check `arecord -l`; reboot after `--install` (modprobe index) |
| Merus sink not found | Merus missing from PulseAudio: `--install` loads `module-alsa-sink` automatically |
| No sound | UCA202 volume (`alsamixer -c CODEC`); PC line-in cable |
| Latency / crackling | Increase `LOOPBACK_LATENCY_MS` (80–120) |

## SD card integration (future)

Injection at SD flash time remains **out of scope** until the checklist above is validated on hardware. Scripts are SSH-deployable only for now.
