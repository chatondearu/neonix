{ config, lib, pkgs, ... }:

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
    nvidiaSettings = true;
    modesetting.enable = true;

    #dynamicBoost.enable = false;
    #powerManagement.enable = true;
    #powerManagement.finegrained = true; # Not working on Nvidia 3000
  };

  environment.variables = {
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000";
  };

  # Fix Nvidia 3000 Dec 2025
  #boot.blacklistedKernelModules = ["nouveau" "nova_core"];

  # Configuration modprobe
  #boot.extraModprobeConfig = ''
  #  options nvidia NVreg_PreserveVideoMemoryAllocations=0
  #  options nvidia NVreg_TemporaryFilePath=/var/tmp
  #'';

  # Services systemd pour suspend/resume/hibernate
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
}