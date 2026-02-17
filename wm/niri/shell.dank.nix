{ pkgs, inputs, ... }:

{
  # DANK LINUX - https://danklinux.com/docs/dankmaterialshell/nixos
  
  imports = [
    # Import the dms-shell module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/dms-shell.nix"
    inputs.dms-plugin-registry.modules.default
  ];

  environment.systemPackages = with pkgs; [
    dgop
    matugen
    cava
    khal

    linux-wallpaperengine # Wallpaper engine for plugin : https://github.com/sgtaziz/dms-wallpaperengine
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

  # users.users.chaton.maid = {
  #   # file.xdg_config."dms-shell/config.json".source = "{{home}}/etc/nixos/wm/niri/dms-shell/config.json";
  # };
}