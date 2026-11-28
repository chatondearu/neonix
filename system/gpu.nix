{
  config,
  pkgs,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Removed Intel GPU tools and drivers (only needed for Intel GPU)
      #intel-gpu-tools
      #intel-media-driver
      #intel-vaapi-driver
      nvidia-vaapi-driver # added for material encoding with Nvenc behind wayland
      libva-vdpau-driver
      #libvdpau-va-gl
      libva
      vulkan-loader
      vulkan-validation-layers
    ];
    extraPackages32 = with pkgs; [
      # Removed Intel GPU tools and drivers (only needed for Intel GPU)
      # intel-gpu-tools
      # intel-media-driver
      # intel-vaapi-driver
      libva-vdpau-driver
      #libvdpau-va-gl
      libva
    ];
  };

  # NVIDIA X11/XWayland video driver
  services.xserver.videoDrivers = ["nvidia"];

  # Enable NVIDIA drivers
  hardware.nvidia = {
    open = false;
    # Pin the running production driver. nvidiaPackages.stable tracks nixpkgs
    # and a bump invalidates Steam Fossilize/vkd3d shader caches.
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.112.07";
      sha256_64bit = "sha256-Gjjs1Tii2mIypzMBhAY69Z6fyUbJCMylVb0HkJhIufA=";
      sha256_aarch64 = "sha256-7qQuOKX9xS/wpKa+bEOqsS2euJjJu182vl+6UU6bxR0=";
      openSha256 = "sha256-nQnXGCcvo4i7eGaVft3Xc9dRUPPH0v9Zi87cfI4i/Ys=";
      settingsSha256 = "sha256-2bWSou/9J3EojhSRXBol/+yGGu2XZ6EuCptb5qXHM14=";
      persistencedSha256 = "sha256-cGMEUXN7WPu822zZDLTSu6Owj8VXG4PNmhe9oKqMMKI=";
    };
    # can add latencies for VR
    #forceFullCompositionPipeline = true; # Force the use of the full composition pipeline for better performance
    nvidiaSettings = true; # Enable Nvidia settings
    modesetting.enable = true; # Enable modesetting required for Wayland

    # Required with nvidia-suspend/resume for reliable S3/s2idle wake on Wayland.
    powerManagement.enable = true;
    powerManagement.finegrained = false;

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
    # dxvk-nvapi: integer 100-99999 as major*100+minor (two-digit minor).
    # 595.112.07 → 59511 (595.11). 59511207 is rejected (>99999).
    DXVK_NVAPI_DRIVER_VERSION = "59511";

    # ADDED REQUIRED FOR SCREEN SHARING (Nvidia + Wayland)
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia"; # Force the usage of nvidia-vaapi-driver
  };

  # Services systemd for suspend/resume/hibernate
  systemd.services.nvidia-suspend.enable = true;
  systemd.services.nvidia-resume.enable = true;
  systemd.services.nvidia-hibernate.enable = true;
}
