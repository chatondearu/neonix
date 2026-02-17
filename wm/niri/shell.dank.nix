{ pkgs, inputs, ... }:

{
  # DANK LINUX - https://danklinux.com/docs/dankmaterialshell/nixos
  
  imports = [
    # Import the dms-shell module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/dms-shell.nix"
    inputs.dms-plugin-registry.modules.default
  ];

  environment.systemPackages = with pkgs; [
    dgop # System monitoring widgets
    matugen # automatic color shemes generation from wallpaper on dms
    cava # audio visualizer
    khal # calendar integration

    linux-wallpaperengine # Wallpaper engine for plugin : https://github.com/sgtaziz/dms-wallpaperengine

    # QtMultimedia backend for DMS sound effects
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];

  programs.dms-shell = {
    enable = true;

    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

    systemd = {
      enable = true;             # Systemd service for auto-start
      restartIfChanged = true;   # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    #enableClipboard = true;            # Clipboard history manager - no more needed in dms latest
    enableVPN = true;                  # VPN management widget
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = true;       # Calendar integration (khal)

    plugins = {
      dockerManager.enable = true;

      # LinuxWallpaperEngine = { # Wallpaper engine for plugin : https://github.com/sgtaziz/dms-wallpaperengine Need steam workshop
      #   enable = true;
      #   src = pkgs.fetchFromGitHub {
      #     owner = "sgtaziz";
      #     repo = "dms-wallpaperengine";
      #     rev = "main";
      #     sha256 = "0513aab5eee2d35d9c0239f3326b6a80b36d8ea96d677b72dcd8cc7ad373a603";
      #   };
      # };
    };
  };

  # Session variables for DMS
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}