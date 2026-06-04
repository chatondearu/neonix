# pi-sound (Raspberry Pi Zero 2 W)

Headless NixOS node for Merus I2S amplification, USB codec loopback, and Squeezelite.

## Boot stack

- [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) `raspberry-pi-02.base`
- Bootloader **`kernel`** (recommended for Pi Zero 2): `kernel.img` + `initrd` on the **FAT firmware** partition — no U-Boot / extlinux on the root partition
- Headless `config.txt`: no `vc4-kms-v3d`, no USB gadget overlay; Merus I2S overlay in `configuration.nix` (boot section)

## Build host (neo-nix)

```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

Substituter `nixos-raspberrypi.cachix.org` is configured in root `nix.nix`.

## Build and flash

```bash
cp .env.example .env   # WIFI_SSID, WIFI_PSK, SSH_PUBLIC_KEY
./build-and-flash.sh /dev/sdX
```

## After first boot

- SSH: `ssh pisound@pi-sound.local`
- Audio services are enabled in `configuration.nix`; tune ALSA / Squeezelite over SSH if needed
