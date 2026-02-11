{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Gaming tools
    mesa-demos           # Show hardware information
    vulkan-tools         # Vulkan utilities (vkcube, vulkaninfo) required by goverlay/vkbasalt
    heroic           # Native GOG, Epic, and Amazon Games Launcher for Linux, Windows and Mac
    joystickwake     # Joystick-aware screen waker
    mangohud         # Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    goverlay         # Graphical UI to configure MangoHud, vkBasalt and other Vulkan/OpenGL overlays
    vkbasalt         # Vulkan post-processing layer for effects like sharpening, color correction
    #mesa             # Ensure last mesa stable on GLF OS
    #oversteer        # Steering Wheel Manager for Linux
    umu-launcher     # Unified launcher for Windows games on Linux using the Steam Linux Runtime and Tools
    wineWowPackages.staging # Open Source implementation of the Windows API on top of X, OpenGL, and Unix (with staging patches)
    winetricks       # Script to install DLLs needed to work around problems in Wine
    piper             # Configure your mouse
    input-remapper   # Change inputs of your joystick
    faugus-launcher   # Launch your windows app
    protonup-qt      # Proton Updater for Steam Play

    gamescope-wsi # HDR won't work without this

    lutris
    # Lutris Config with additional libraries
    #  (lutris.override {
    #    extraLibraries = p: [ p.libadwaita p.gtk4 ];
    #  })

    ## VR
    wlx-overlay-s # Overlay for WayVR
    wayvr-dashboard # Dashboard for WayVR
    android-tools # Android tools for debugging and development
  ];

  environment.variables = {
    MESA_SHADER_CACHE_MAX_SIZE = "12G";
  };

  # Hardware support
  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true; # Xbox One Controller
  hardware.xpadneo.enable = true; # Xbox One Controller with wireless dongle
  hardware.opentabletdriver.enable = true;

  services.ratbagd.enable = true; # Ratbagd is a daemon for managing input devices like Logitech G502

  programs.gamemode.enable = true;

  # Enable ADB for Android development and Quest VR headset
  programs.adb.enable = true;

  # Gamescope configuration
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Install Steam.
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    package = pkgs.steam.override {
      extraEnv = {
        OBS_VKCAPTURE = true;
      };
    };

    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  # Issues with adding steam library on new disk
  # to add it manualy : '$ steam steam://open/console'
  # then in the steam console tab : 'library_folder_add /games/SteamLibrary'
  # see: 

  # Create symlinks for goverlay to detect vkBasalt (hardcoded paths in /usr/ which don't exist on NixOS)
  system.activationScripts.vkbasalt-compat = ''
    # Create /usr/share/vulkan structure for goverlay detection
    mkdir -p /usr/share/vulkan/implicit_layer.d
    ln -sf /run/current-system/sw/share/vulkan/implicit_layer.d/vkBasalt.json /usr/share/vulkan/implicit_layer.d/vkBasalt.json

    # Create /usr/lib symlink for libvkbasalt.so
    mkdir -p /usr/lib
    if [ -f "${pkgs.vkbasalt}/lib/libvkbasalt.so" ]; then
      ln -sf "${pkgs.vkbasalt}/lib/libvkbasalt.so" /usr/lib/libvkbasalt.so
    fi
  '';

  ## VR

  # WiVRn is a runtime for wireless VR devices
  services.wivrn = {
    enable = true;
    openFirewall = true; # Required for wireless streaming
    defaultRuntime = true;
  };

  # Monado is a runtime for VR devices
  #services.monado = {
  #  enable = true;
  #  defaultRuntime = true;
  #};

  #systemd.user.services.monado = {
  #  environment = {
  #    STEAMVR_LH_ENABLE = "1";
  #    XRT_COMPOSITOR_COMPUTE = "1";
  #    XRT_COMPOSITOR_FORCE_XCB = "1"; # Force the use of XCB
   #   IPC_EXIT_ON_DISCONNECT = "1"; # Exit the application when the connection to the device is lost
  #    U_PACING_COMP_MIN_TIME_MS = "5"; # Minimum time for the compositor to render the frame

   #   DXRT_ENABLE_GPL = "1"; # Enable GPL
   #   DXRT_BUILD_DRIVER_QUEST_LINK = "1"; # Build the driver question link

   #   #WMR_HANDTRACKING = "0"; # Disable hand tracking
  #  };

  #  serviceConfig = {
  #    Nice = 20; # Low priority for the service
  #  };
  #};

  services.udev.extraRules = ''
    # Steam Deck controllers
    SUBSYSTEM=="input", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="3106", MODE="0660", GROUP="input"

    # Meta Quest VR headsets (Quest 1, 2, 3)
    # Vendor ID 2833 = Oculus/Meta
    # Product IDs: 0183 (Quest 1), 0186 (Quest 1 in file transfer mode), 
    #              01a0 (Quest 2), 01a1 (Quest 2 in file transfer mode),
    #              0360 (Quest 3), 0361 (Quest 3 in file transfer mode)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2833", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2833", MODE="0666"

    # Valve Index and other VR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2d40", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2d40", MODE="0666"
  '';
}