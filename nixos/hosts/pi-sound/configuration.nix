{
  config,
  pkgs,
  lib,
  ...
}: let
  wifiSsid = builtins.getEnv "WIFI_SSID";
  wifiPsk = builtins.getEnv "WIFI_PSK";
  sshPublicKey = builtins.getEnv "SSH_PUBLIC_KEY";
  hostname = "pi-sound";
  usbCard = "CODEC";
  i2sCard = "sndrpimerusamp";
in {
  system.stateVersion = "25.11";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # --- Pi Zero 2 W boot (nixos-raspberrypi) ---

  boot.loader.raspberry-pi.bootloader = "kernel";
  boot.supportedFilesystems = ["vfat" "ext4"];

  hardware.raspberry-pi.config = {
    all = {
      options = {
        camera_auto_detect.enable = lib.mkForce false;
        display_auto_detect.enable = lib.mkForce false;
        max_framebuffers.enable = lib.mkForce false;
        disable_fw_kms_setup.enable = lib.mkForce true;
        arm_boost.enable = lib.mkForce false;
      };
      base-dt-params.i2s = {
        enable = true;
        value = "on";
      };
      dt-overlays = {
        vc4-kms-v3d.enable = lib.mkForce false;
        dwc2.enable = lib.mkForce false;
        merus-amp.enable = true;
      };
    };
    cm4.options.otg_mode.enable = lib.mkForce false;
    cm5.dt-overlays.dwc2.enable = lib.mkForce false;
  };

  # nixos-raspberrypi leaves stray "dtoverlay=" lines that confuse some firmware parsers
  boot.loader.raspberry-pi.configTxtPackage = pkgs.writeTextFile {
    name = "config.txt";
    text =
      lib.concatStringsSep "\n"
      (lib.filter (
          line:
            line
            != ""
            && line != "dtoverlay="
            && line != "[cm4]"
            && line != "[cm5]"
        ) (
          lib.splitString "\n" config.hardware.raspberry-pi.config-generated
        ))
      + "\n";
  };

  # --- Network and access ---

  networking = {
    hostName = hostname;
    useDHCP = lib.mkDefault true;
    wireless = {
      iwd.enable = true;
      interfaces = ["wlan0"];
      networks."${wifiSsid}" = {
        psk = wifiPsk;
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.pisound = {
    isNormalUser = true;
    description = "Pi sound node admin";
    extraGroups = ["wheel" "audio"];
    openssh.authorizedKeys.keys = ["${sshPublicKey}"];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.defaultPackages = lib.mkForce [];
  services.udisks2.enable = false;

  environment.systemPackages = with pkgs; [
    git
    helix
    htop
    parted
    gptfdisk
  ];

  # --- Audio stack (debug over SSH; do not change without testing on hardware) ---

  boot.extraModprobeConfig = ''
    options snd-usb-audio index=1
  '';

  hardware.alsa.enable = true;
  services.pulseaudio.enable = false;

  environment.etc."asound.conf".text = ''
    pcm.merus {
      type hw
      card ${i2sCard}
    }

    pcm.usbcodec {
      type plug
      slave.pcm {
        type hw
        card ${usbCard}
      }
    }
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="sound", ENV{ID_ID}=="${usbCard}", SYMLINK+="snd/usb_codec"
  '';

  services.squeezelite = {
    enable = true;
    extraArguments = "-o merus -n ${hostname}";
  };

  systemd.services.usb-audio-loop = {
    description = "ALSA loopback USB to I2S";
    wantedBy = ["multi-user.target"];
    after = ["sound.target"];
    serviceConfig = {
      ExecStart = "${pkgs.alsa-utils}/bin/alsaloop -C usbcodec -P merus -t 50000";
      Restart = "always";
      RestartSec = "5";
    };
  };
}
