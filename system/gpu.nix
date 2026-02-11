{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.glf.nvidia_config;
  nvidiaDriverPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "590.48.01";
    sha256_64bit = "sha256-ueL4BpN4FDHMh/TNKRCeEz3Oy1ClDWto1LO/LWlr1ok=";
    sha256_aarch64 = "sha256-FOz7f6pW1NGM2f74kbP6LbNijxKj5ZtZ08bm0aC+/YA=";
    openSha256 = "sha256-hECHfguzwduEfPo5pCDjWE/MjtRDhINVr4b1awFdP44=";
    settingsSha256 = "sha256-NWsqUciPa4f1ZX6f0By3yScz3pqKJV1ei9GvOF8qIEE=";
    persistencedSha256 = "sha256-wsNeuw7IaY6Qc/i/AzT/4N82lPjkwrhxidKWUtcwW8=";
  };
in
{
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

  # Enable NVIDIA drivers
  hardware.nvidia = {
    open = true;
    package = nvidiaDriverPackage;
    nvidiaSettings = true;
    modesetting.enable = true;

    dynamicBoost.enable = false;
    powerManagement.enable = true;
    #powerManagement.finegrained = true; # Not working on Nvidia 3000
  };

  environment.variables = {
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000";
  };

  # Fix Nvidia 3000 Dec 2025
  # boot.blacklistedKernelModules = ["nouveau" "nova_core"];

  # Configuration modprobe
  # boot.extraModprobeConfig = ''
  #   options nvidia NVreg_PreserveVideoMemoryAllocations=0
  #   options nvidia NVreg_TemporaryFilePath=/var/tmp
  # '';

  # Services systemd pour suspend/resume/hibernate
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
}