{pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    # Gaming tools
    #mesa            # Ensure last mesa stable on GLF OS
    mesa-demos # Show hardware information
    mangohud # Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    vulkan-tools # Vulkan utilities (vkcube, vulkaninfo) required by goverlay/vkbasalt
    vkbasalt # Vulkan post-processing layer for effects like sharpening, color correction
    wineWow64Packages.staging # Open Source implementation of the Windows API on top of X, OpenGL, and Unix (with staging patches)
    winetricks # Script to install DLLs needed to work around problems in Wine
    goverlay # Graphical UI to configure MangoHud, vkBasalt and other Vulkan/OpenGL overlays
    gamescope-wsi # HDR won't work without this

    # Input devices
    #oversteer       # Steering Wheel Manager for Linux
    joystickwake # Joystick-aware screen waker
    piper # Configure your mouse
    input-remapper # Change inputs of your joystick

    # Launchers
    heroic # Native GOG, Epic, and Amazon Games Launcher for Linux, Windows and Mac
    umu-launcher # Unified launcher for Windows games on Linux using the Steam Linux Runtime and Tools
    faugus-launcher # An umu based launcher for Windows games on Linux using the Steam Linux Runtime and Tools
    #cartbridge      # Cartridge Bridge. A GTK4 + Libadwaita game launcher : https://codeberg.org/kramo/cartridges
    #lutris          # Game launcher for Linux, Windows, and macOS
    # Lutris Config with additional libraries
    (lutris.override {
      extraLibraries = p: [
        p.libadwaita
        p.gtk4
      ];
    })

    itch
    itch-dl

    (prismlauncher.override {
      # Add binary required by some mod
      additionalPrograms = [ ffmpeg ];

      # Change Java runtimes available to Prism Launcher
      jdks = [
        graalvmPackages.graalvm-ce
        zulu8
        zulu17
        zulu
      ];
    })
  ];

  programs.gamemode.enable = true;

  # Gamescope configuration
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Hardware support for devices
  # Dongle Microsoft (045e:02fe) via xone; do not enable xpadneo unless Bluetooth is on.
  hardware.xone.enable = true;
  hardware.enableAllFirmware = true;
  hardware.xpadneo.enable = false;
  # hardware.opentabletdriver.enable = true; # Disabled: no tablet detected, wastes resources scanning
  services.ratbagd.enable = true; # Ratbagd is a daemon for managing input devices like Logitech G502

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

  imports = [
    ./gamestream.nix
    ./steam.nix
    ./vr/vr.nix
  ];
}
