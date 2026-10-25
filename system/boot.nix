{
  lib,
  pkgs,
  ...
}: let
  # Slow spin-up HDD + NVMe enumeration after initrd; 5s was too short at boot.
  gameDiskDeviceTimeout = "90s";
  gameDiskMountUnits = [
    "games.mount"
    "hdd.mount"
    "hdd-share.mount"
    "games-SteamLibrary-steamapps-compatdata.mount"
  ];
in {
  # Bootloader.
  boot = {
    initrd = {
      systemd.enable = true;
    };

    # QEMU user emulation for cross-building aarch64 SD images (e.g. pi-sound on Pi Zero 2 W)
    binfmt.emulatedSystems = ["aarch64-linux"];

    loader = {
      # systemd-boot on UEFI
      #systemd-boot.enable = true; # Disabled because it's not working with limine
      efi.canTouchEfiVariables = true;

      # Limine bootloader for UEFI
      limine = {
        enable = true;
        efiSupport = true;
        style.wallpapers = [pkgs.nixos-artwork.wallpapers.simple-dark-gray-bootloader.gnomeFilePath];
        maxGenerations = 10;
        secureBoot.enable = true;
      };
      systemd-boot.enable = lib.mkForce false; # Disable systemd-boot
    };

    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };

    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_EnableGpuFirmware=1"
      "nvidia.NVreg_RmRestrictDeviceFileAccess=0"
      # Prefer ACPI S3 "deep" over s2idle when firmware allows (see /sys/power/mem_sleep).
      "mem_sleep_default=deep"
    ];
  };

  environment.systemPackages = with pkgs; [
    sbctl # Secure Boot Control Tool for limine
  ];

  systemd.services.nix-daemon = {
    environment = {
      TMPDIR = "/var/tmp";
    };
  };

  fileSystems."/games" = {
    device = "/dev/disk/by-partuuid/fac02d23-340d-499a-8a90-3c799fa1a3c6";
    fsType = "ntfs3";
    options = [
      "nofail" # Allows system to continue to boot if drive cannot be mounted
      "rw"
      "exec" # Allows execution of files
      "uid=1000" # Assign ownership to the user
      "gid=100" # Assign to the 'users' group
      "umask=000" # Permissions 755 for directories, 644 for files
      "prealloc"
      "discard" # Allows the filesystem to discard unused blocks
      "x-systemd.device-timeout=${gameDiskDeviceTimeout}"
    ];
  };

  # Keep Proton prefixes off NTFS while preserving a Steam library on /games.
  systemd.mounts = [
    {
      what = "/home/chaton/.local/share/Steam/compatdata";
      where = "/games/SteamLibrary/steamapps/compatdata";
      type = "none";
      options = "bind";
      requires = ["games.mount"];
      after = ["games.mount"];
      wantedBy = ["multi-user.target"];
    }
  ];

  systemd.tmpfiles.rules = [
    "d /home/chaton/.local/share/Steam/compatdata 0755 chaton users - -"
  ];

  fileSystems."/hdd" = {
    device = "/dev/disk/by-label/hdd-dev";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "x-systemd.device-timeout=${gameDiskDeviceTimeout}"
    ];
  };

  fileSystems."/hdd/share" = {
    device = "/dev/disk/by-label/hdd-share";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=000"
      "nofail"
      "x-systemd.device-timeout=${gameDiskDeviceTimeout}"
      "x-systemd.idle-timeout=10min"
    ];
  };

  # nofail + short device wait at boot leaves mounts dead if the disk appears later.
  systemd.services.game-disks-mount-retry = {
    description = "Retry game disk mounts when block devices were not ready at early boot";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script =
      lib.concatMapStringsSep "\n" (unit: ''
        if ! ${pkgs.systemd}/bin/systemctl is-active --quiet ${unit}; then
          ${pkgs.systemd}/bin/systemctl start ${unit} || true
        fi
      '')
      gameDiskMountUnits;
  };
}
