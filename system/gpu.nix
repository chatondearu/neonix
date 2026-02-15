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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true; # Force the use of the full composition pipeline for better performance
    nvidiaSettings = true; # Enable Nvidia settings
    modesetting.enable = true; # Enable modesetting

    powerManagement = {
      enable = false; # disable power management for nvidia because we don't hibernate
      finegrained = false; # correct for RTX 3000 but we don't use it
    };
  };

  environment.variables = {
    ENERGY_PERF_BIAS = "performance";
    GSK_RENDERER = "ngl"; # use the new gles renderer for better performance (GTK4)

    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # 12GB shader disk cache
  };

  # Services systemd for suspend/resume/hibernate
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = false;
}