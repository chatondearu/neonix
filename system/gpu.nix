{
  config,
  lib,
  pkgs,
  ...
}:

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

  # NVIDIA X11/XWayland video driver
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable NVIDIA drivers
  hardware.nvidia = {
    open = false; # TODO try proprietary driver instead
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = true; # Force the use of the full composition pipeline for better performance
    nvidiaSettings = true; # Enable Nvidia settings
    modesetting.enable = true; # Enable modesetting

    # Add these for VR:
    prime = {
      offload.enable = false; # You don't have hybrid graphics
    };
  };

  environment.variables = {
    ENERGY_PERF_BIAS = "performance";
    GSK_RENDERER = "ngl"; # use the new gles renderer for better performance (GTK4)

    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # 12GB shader disk cache

    # Add these for better gaming/VR performance:
    __GL_THREADED_OPTIMIZATION = "1";
    __GL_SYNC_TO_VBLANK = "0"; # Better for VR, disable for desktop if tearing occurs
    PROTON_ENABLE_NVAPI = "1";
    DXVK_NVAPI_DRIVER_VERSION = "58011902"; # Match your driver version
  };

  # Services systemd for suspend/resume/hibernate
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = false;
}
