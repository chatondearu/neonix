# TODO — entrée USB → enceintes Merus (phase 2)

**Statut :** hors scope de l’env Nix `raspberry/` pour l’instant.  
**Objectif :** reproduire le comportement de [`pi-sound`](../../nixos/hosts/pi-sound/configuration.nix) — codec USB Behringer UCA202/UCA222 (`CODEC`) routé vers le Merus (`sndrpimerusamp`).

Ne pas intégrer au workflow SD (`apply-merus-config`) tant que le prototype SSH n’est pas validé sur le hardware.

## Contexte

| Stack | pi-sound (NixOS) | odio (Raspberry Pi OS) |
|-------|------------------|------------------------|
| Audio | ALSA pur, PulseAudio désactivé | PulseAudio cœur odio |
| USB → Merus | `alsaloop` systemd | **À explorer** via PulseAudio |

pi-sound utilise `alsaloop` parce que NixOS n’a pas PulseAudio. Sur odio, une route PulseAudio devrait éviter l’exclusion mutuelle avec AirPlay / Spotify / Bluetooth.

## Référence pi-sound

Fichiers Nix équivalents à reproduire ou remplacer :

- `options snd-usb-audio index=1` — Merus card 0, USB card 1
- `/etc/asound.conf` — PCM `merus`, `usbcodec` (carte `CODEC`)
- udev : symlink `snd/usb_codec` si `ID_ID==CODEC`
- systemd : `alsaloop -C usbcodec -P merus -t 50000`

Voir aussi [`system/devices/doc-raudio.md`](../../system/devices/doc-raudio.md).

## Piste préférée : PulseAudio

Sur le Pi odio (user `odio`), après phase 1 Merus OK :

```bash
pactl list short sources
pactl list short sinks
# Merus sink + USB source, then e.g.:
pactl load-module module-loopback source=<usb_source> sink=<merus_sink> latency_msec=50
```

À valider :

- Merus visible comme sink PulseAudio (pas seulement ALSA)
- Latence acceptable (~50 ms comme pi-sound)
- Coexistence avec AirPlay / Spotify (pas d’arrêt de PulseAudio)
- Formats / canaux USB vs I2S

## Piste fallback : alsaloop (test ponctuel)

Acceptable **uniquement** pour isoler un problème matériel USB, pas comme config permanente odio :

```bash
# Stop odio PulseAudio for the test
systemctl --user stop pulseaudio.service pulseaudio.socket

# Manual loop (adjust cards after aplay -l / arecord -l)
alsaloop -C plughw:CODEC,0 -P hw:sndrpimerusamp,0 -t 50000
```

Conflit garanti avec la stack odio si les deux tournent en parallèle.

## Checklist SSH (phase 2)

- [ ] Phase 1 Merus validée (`speaker-test` OK)
- [ ] Codec USB branché (OTG/adaptateur Pi Zero 2 W si besoin)
- [ ] `arecord -l` → carte `CODEC` (index 1 si modprobe appliqué)
- [ ] Test route PulseAudio `module-loopback`
- [ ] Signal line-in USB audible sur enceintes Merus
- [ ] Latence mesurée / acceptable
- [ ] AirPlay ou Spotify toujours fonctionnels avec la route active (ou documenter la limite)

## Critères d’intégration future

Une fois la checklist OK en SSH, décider :

1. **Doc only** — garder les commandes dans ce fichier
2. **Scripts dans `raspberry/odio/`** — ex. `install-usb-route.sh` à lancer en SSH (pas injection SD)
3. **Injection SD** — seulement si la config est stable et reproductible

Ne pas choisir l’option 3 avant validation complète en 1 et 2.
