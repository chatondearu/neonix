{ config, pkgs, lib, ... }:

let
  # secrets = import ./secrets.nix;
  wifiSsid = builtins.getEnv "WIFI_SSID";
  wifiPsk = builtins.getEnv "WIFI_PSK";
  musicAssistantUrl = builtins.getEnv "MUSIC_ASSISTANT_URL";
  sshPublicKey = builtins.getEnv "SSH_PUBLIC_KEY";
  hostname = "pi-sound";
  usbCard = "CODEC";
  i2sCard = "sndrpimerusamp";
in
{
  nixpkgs.overlays = [
    (final: prev: {
      efivar = prev.efivar.overrideAttrs (oldAttrs: {
        # Désactivation de la transformation des warnings en erreurs fatales
        env = (oldAttrs.env or {}) // {
          NIX_CFLAGS_COMPILE = toString (oldAttrs.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error";
        };
      });
    })
  ];

  nixpkgs.config = {
    allowBroken = true;  # pkgs.efivar is marked broken for armv7l
    config.allowUnsupportedSystem = true; # pkgs.uboot-rpi_0_w_defconfig-2025.10 not supported for armv7l
  };

  system.stateVersion = "25.11";

  nix = {
    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = 524288000; # 500MB

      # Limit build parallelism to prevent OOM during heavy builds
      max-jobs = 2;
      cores = 2;

      # Add niri cache to speed up builds
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = [ "root" "nixos" "chaton" ];
    };
  };

  sdImage.compressImage = false;

  # --- Optimisation Matérielle et Boot ---
  boot.initrd.systemd.enable = true;
  boot.zfs.forceImportRoot = false;

  # Only ZFS and vfat (for boot) - disable others to shrink image
  # Default SD image enables cifs/ntfs/btrfs etc which pulls in samba (~600MB)
  boot.supportedFilesystems = lib.mkForce [ "vfat" "zfs" ];

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  # Verrouillage noyau de l'index USB (Méthode ALSA standard, plus fiable que Udev seul)
  boot.extraModprobeConfig = ''
    options snd-usb-audio index=1
  '';

  # Désactivation de la génération de ce fichier pour débloquer la cross-compilation
  environment.etc."sysctl.d/55-nixos-aslr-entropy.conf".enable = false;

  ## Réseau
  systemd.network = {
    enable = true;
    networks."10-wired" = {
      matchConfig.Name = "eth0"; # Ajuster selon la sortie de `ip link`
      networkConfig.DHCP = "yes";
    };
  };

  networking = {
    hostName = hostname;
    useDHCP = false; # Suffisant pour Ethernet filaire (KISS)

    wireless = {
      iwd.enable = true;
      interfaces = [ "wlan0" ];
      networks = {
        "${wifiSsid}" = {
          psk = wifiPsk;
        };
      };
    };
  };

  # Découverte mDNS (facilite la connexion via ssh root@rpi-audio.local)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
  };

  # Serveur SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.pisound = {
    isNormalUser = true;
    description = "RPI Admin";
    extraGroups = [ "wheel" "audio" ];
    openssh.authorizedKeys.keys = [
      "${sshPublicKey}"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # --- Socle Audio (ALSA pur) ---
  hardware.alsa.enable = true;
  services.pulseaudio.enable = false;

  # Injecter les paramètres I2S directement dans la partition FAT32 (Bootloader)
  sdImage.populateFirmwareCommands = lib.mkAfter ''
    echo "dtparam=i2s=on" >> config.txt
    echo "dtoverlay=merus-amp" >> config.txt
  '';

  # Définition des alias ALSA purs
  environment.etc."asound.conf".text = ''
    pcm.merus {
      type hw
      card ${i2sCard}
    }
    
    type plug
      slave.pcm {
        type hw
        card ${usbCard}
      }
    }
  '';

  # Règle Udev pour symlink persistant (sécurité supplémentaire)
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", ATTRS{id}="${usbCard}", SYMLINK+="snd/usb_codec"
  '';

  # --- Intégration Music Assistant (SlimProto) ---
  services.squeezelite = {
    enable = true;
    # -o : Périphérique de sortie audio (alias ALSA "merus")
    # -n : Nom exposé sur le réseau
    extraArgs = "-o merus -n ${hostname}";
  };

  # --- Routage direct PC USB -> I2S ---
  systemd.services.usb-audio-loop = {
    description = "ALSA loopback USB to I2S";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.alsa-utils}/bin/alsaloop -C usbcodec -P merus -t 50000";
      Restart = "always";
      RestartSec = "5";
    };
  };

  # --- Réduction d'empreinte système ---
  environment.defaultPackages = lib.mkForce [];
  services.udisks2.enable = false;

  environment.systemPackages = with pkgs; [
    git
    helix
    htop
    parted
    gptfdisk
  ];
}