{
  lib,
  config,
  pkgs,
  ...
}: {
  # Security hardening for HSI compliance
  security = {
    forcePageTableIsolation = true;
    # false: NixOS adds kernel param nohibernate when this is true (blocks S4).
    protectKernelImage = false;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = false; # true;
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

  boot.resumeDevice = "/dev/mapper/vg0-swap";

  swapDevices = [
    {
      device = "/dev/mapper/vg0-swap";
      priority = 1;
    }
  ];

  environment.systemPackages = with pkgs; [
    # Utilities
    wget
    ghostty
    #nano - set by default
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

    (writeShellScriptBin "suspend-preflight" (builtins.readFile ../scripts/system/suspend-preflight.sh))
  ];
}
