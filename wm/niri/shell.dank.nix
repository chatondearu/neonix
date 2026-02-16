{ pkgs, inputs, ... }:

{
  # DANK LINUX - https://danklinux.com/docs/dankmaterialshell/nixos
  
  imports = [
    # Import the dms-shell module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/dms-shell.nix"
  ];

  environment.systemPackages = with pkgs; [
    dgop
    matugen
    cava
    khal
  ];

  programs.dms-shell = {
    enable = true;

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
  };
}