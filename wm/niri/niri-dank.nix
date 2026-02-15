{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.dms.nixosModules.dank-material-shell
    inputs.niri.nixosModules.niri
  ];

  # Enable niri compositor
  programs.niri.enable = true;

  # Display manager configuration for Niri
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Wayland essentials
    xwayland-satellite
    xwayland-run

    # Application launcher and UI
    fuzzel # Application launcher
    
    # Screenshot tools
    grim
    slurp
    swappy # Screenshot editor
    
    # Clipboard and media
    wl-clipboard
    cliphist # Clipboard history
    wf-recorder
    
    # System utilities
    wlsunset # Screen color temperature
    mako # Notification daemon
    xfce.thunar # File manager
    
    # Media control
    playerctl # Media player controller
    pavucontrol # PulseAudio volume control
    
    # Session management
    wlogout # Logout menu
    
    # Terminal emulator (if not already in system.nix)
    kitty
  ];

  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    # Core features
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    enableVPN = true;                  # VPN management widget
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = true;       # Calendar integration (khal)
    enableClipboardPaste = true;       # Pasting items from the clipboard (wtype)
  };

  # Disable niri-flake polkit service conflict
  systemd.user.services.niri-flake-polkit.enable = false;

  # XDG Portal configuration for Niri
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      niri.default = [ "gnome" "gtk" ];
    };
  };

  # Enable Xwayland support
  programs.xwayland.enable = true;

  # Session variables for Niri
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Electron/Chrome apps
  };
}
