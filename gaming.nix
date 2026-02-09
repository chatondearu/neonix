{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Gaming tools
    mesa-demos           # Show hardware information
    vulkan-tools         # Vulkan utilities (vkcube, vulkaninfo) required by goverlay/vkbasalt
    heroic           # Native GOG, Epic, and Amazon Games Launcher for Linux, Windows and Mac
    joystickwake     # Joystick-aware screen waker
    linuxKernel.packages.linux_6_18.hid-tmff2
    mangohud         # Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    goverlay         # Graphical UI to configure MangoHud, vkBasalt and other Vulkan/OpenGL overlays
    vkbasalt         # Vulkan post-processing layer for effects like sharpening, color correction
    #mesa             # Ensure last mesa stable on GLF OS
    #oversteer        # Steering Wheel Manager for Linux
    umu-launcher     # Unified launcher for Windows games on Linux using the Steam Linux Runtime and Tools
    wineWowPackages.staging # Open Source implementation of the Windows API on top of X, OpenGL, and Unix (with staging patches)
    winetricks       # Script to install DLLs needed to work around problems in Wine
    piper             #Configure your mouse
    input-remapper   #Change inputs of your joystick
    faugus-launcher   #Launch your windows app

    lutris
    # Lutris Config with additional libraries
    #  (lutris.override {
    #    extraLibraries = p: [ p.libadwaita p.gtk4 ];
    #  })

  ];

  # Hardware support
  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true; # Xbox One Controller
  hardware.xpadneo.enable = true; # Xbox One Controller with wireless dongle
  hardware.opentabletdriver.enable = true;
  services.ratbagd.enable = true; # Ratbagd is a daemon for managing input devices like Logitech G502
  programs.gamemode.enable = true;

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

}