{ lib, config, pkgs, ... }:

{
  time.hardwareClockInLocalTime = true;
  time.timeZone = "Europe/Paris";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-gpu-tools
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      #libvdpau-va-gl
      libva
      vulkan-loader
      vulkan-validation-layers
    ];
    extraPackages32 = with pkgs; [
      intel-gpu-tools
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      #libvdpau-va-gl
      libva  
    ];
  };

  environment.variables = {
    MESA_SHADER_CACHE_MAX_SIZE = "12G";
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
      randomEncryption ={
        enable = true;
        allowDiscards = true;
      };
    }
  ];

  nix = {
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
    settings = {
      auto-optimise-store = true;
    };
  };
}
