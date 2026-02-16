{ pkgs, inputs, ... }:

{
  # Disable the stable niri module
  disabledModules = [ "programs/wayland/niri.nix" ];

  imports = [
    # Import the niri module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/niri.nix"
    ./shell.dank.nix
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
    mako # Notification daemon
    
    # Media control
    playerctl # Media player controller
    pavucontrol # PulseAudio volume control
    
    # Session management
    wlogout # Logout menu
    
    # Terminal emulator (if not already in system.nix)
    ghostty

     # Multi-display management
    kanshi # Auto-configure displays
    wdisplays # GUI for display configuration
    
    # Screen locking and idle
    swaylock # Screen locker
    swayidle # Idle management
    
    # Color picker and tools
    grim
    slurp
    wl-color-picker
    
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
    adwaita-icon-theme
    gnome-themes-extra
    
    # Network management GUI
    networkmanagerapplet
    
    # System monitoring
    btop # Better top
    
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

  # Automatic display configuration with kanshi
  systemd.user.services.kanshi = {
    description = "Kanshi display configuration daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi";
      Restart = "on-failure";
    };
  };

  # Automatic screen locking with swayidle
  systemd.user.services.swayidle = {
    description = "Idle manager for Wayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 300 '${pkgs.swaylock}/bin/swaylock -f' \
          timeout 600 'niri msg action power-off-monitors' \
          resume 'niri msg action power-on-monitors' \
          before-sleep '${pkgs.swaylock}/bin/swaylock -f'
      '';
      Restart = "on-failure";
    };
  };

  # Clipboard history daemon
  systemd.user.services.cliphist = {
    description = "Clipboard history daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
  };

  # GTK theme configuration for consistent appearance
  programs.dconf.enable = true;
  
  # Optional: Set default applications
  # xdg.mime.defaultApplications = {
  #   "text/html" = "firefox.desktop";
  #   "x-scheme-handler/http" = "firefox.desktop";
  #   "x-scheme-handler/https" = "firefox.desktop";
  #   "application/pdf" = "zathura.desktop";
  #   "image/*" = "imv.desktop";
  # };

  # Font configuration for better text rendering
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Fira Code" "DejaVu Sans Mono" ];
      sansSerif = [ "Roboto" "DejaVu Sans" ];
      serif = [ "DejaVu Serif" ];
    };
    # Enable subpixel rendering
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
    # Better hinting
    hinting = {
      enable = true;
      style = "slight";
    };
  };
}
