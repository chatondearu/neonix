{
  lib,
  pkgs,
  ...
}:

{
  # Bootloader.
  boot = {
    initrd = {
      systemd.enable = true;
    };

    loader = {
      # systemd-boot on UEFI
      #systemd-boot.enable = true; # Disabled because it's not working with limine
      efi.canTouchEfiVariables = true;

      # Limine bootloader for UEFI
      limine = {
        enable = true;
        efiSupport = true;
        style.wallpapers = [ pkgs.nixos-artwork.wallpapers.simple-dark-gray-bootloader.gnomeFilePath ];
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
      "uid=1000"     # Assigne la propriété à ton utilisateur
      "gid=100"      # Assigne au groupe 'users'
      "umask=022"    # Permissions 755 pour les dossiers, 644 pour les fichiers
      "windows_names" # Allows Windows-style file names
      "x-systemd.device-timeout=5s"
    ];
  };

  fileSystems."/hdd" = {
    device = "/dev/disk/by-uuid/CCE4A03CE4A02AA2";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"     # Assigne la propriété à ton utilisateur
      "gid=100"      # Assigne au groupe 'users'
      "umask=022"    # Permissions 755 pour les dossiers, 644 pour les fichiers
      "nofail"       # Boot sans kernel panic si le HDD crashe
      "windows_names" # Allows Windows-style file names
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=10min"
    ];
  };
}
