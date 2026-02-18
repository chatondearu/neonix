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

    # Application launcher
    fuzzel

    # Screenshot tools
    grim
    slurp
    swappy # Screenshot editor

    # Media control
    playerctl # Media player controller
    pavucontrol # PulseAudio volume control

    # Multi-display management
    wdisplays # GUI for display configuration

    # File management
    nautilus # GTK4/libadwaita, integrates with DMS dynamic theming
    gvfs # Virtual filesystem (for network shares, etc.)
    yazi # TUI file manager (Rust, image previews in Ghostty)

    # Image viewer
    imv # Wayland image viewer

    # PDF viewer
    zathura

    # GTK themes
    papirus-icon-theme
    adwaita-icon-theme
    gnome-themes-extra

    # Network management GUI
    networkmanagerapplet
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
