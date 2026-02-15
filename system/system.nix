{ lib, config, pkgs, ... }:

{
   # Additional security hardening for HSI compliance
  security = {
    forcePageTableIsolation = true;
    protectKernelImage = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  services = {
    # for SSD/NVME
    fstrim.enable = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 5;
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/da2c2ea6-323f-426e-9644-328248df2efa";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    }
  ];

    # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # utils
    wget
    ghostty # Terminal emulator
    helix # Text editor in rust for the terminal
    vlc

    # disk utilities
    kdePackages.partitionmanager
    testdisk
    exfat
    exfatprogs

    # zip utilities
    zip
    unzip
    p7zip
    rar
    unrar
    gzip
    xz

    # apps
    pciutils
    usbutils
    ffmpeg
    ffmpegthumbnailer
  ];
}
