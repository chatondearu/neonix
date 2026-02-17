{ pkgs, inputs, ... }:

{
  # Disable the stable niri module
  disabledModules = [ "programs/wayland/niri.nix" ];

  imports = [
    # Import the niri module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/niri.nix"
    ./shell.dank.nix
    ./greeter.dank.nix
  ];

  # Enable niri compositor
  programs.niri.enable = true;

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
    # wl-clipboard
    # cliphist # Clipboard history
    # wf-recorder
    
    # System utilities 
    mako # Notification daemon
    
    # Media control
    playerctl # Media player controller
    pavucontrol # PulseAudio volume control
    
    # Session management
    wlogout # Logout menu
    
    # Terminal emulator (if not already in system.nix)
    ghostty

    # Multi-display management
    wdisplays # GUI for display configuration
    
    # Screen locking and idle
    swaylock # Screen locker
    swayidle # Idle management
    
    # Color picker and tools
    # grim
    # slurp
    # wl-color-picker
    
    # File management
    xfce.thunar # File manager
    xfce.thunar-volman # Thunar volume manager
    xfce.thunar-archive-plugin # Archive support for Thunar
    gvfs # Virtual filesystem (for network shares, etc.)
    
    # Image viewer
    imv # Wayland image viewer
    
    # PDF viewer
    zathura # Minimal PDF viewer
    
    # GTK themes for better appearance
    papirus-icon-theme
    adwaita-icon-theme
    gnome-themes-extra
    
    # Network management GUI
    networkmanagerapplet
    
    # Color temperature with more features
    # wlsunset is already installed, but gammastep offers more control
    gammastep
  ];

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



  # GTK theme configuration for consistent appearance
  programs.dconf.enable = true;

}
