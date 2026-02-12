{ lib, config, pkgs, ... }:

{
  time.hardwareClockInLocalTime = true;
  time.timeZone = "Europe/Paris";

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
}
