{ lib, config, pkgs, ... }:

{
  # Security hardening for HSI compliance
  security = {
    forcePageTableIsolation = true;
    protectKernelImage = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # SSD/NVMe TRIM
  services.fstrim.enable = true;

  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 75;
    priority = 5;
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/da2c2ea6-323f-426e-9644-328248df2efa";
      # randomEncryption disabled: nohibernate is set so swap is ephemeral,
      # and dm_crypt causes deadlocks under memory pressure (bio alloc failure)
    }
  ];

  environment.systemPackages = with pkgs; [
    # Utilities
    wget
    ghostty
    helix
    vlc

    # Disk utilities
    kdePackages.partitionmanager
    testdisk
    exfat
    exfatprogs

    # Archive utilities
    zip
    unzip
    p7zip
    rar
    unrar
    gzip
    xz

    # Hardware info
    pciutils
    usbutils
    ffmpeg
    ffmpegthumbnailer
  ];
}
