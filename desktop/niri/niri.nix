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
    # Portals
    gnome-keyring

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

  # XDG Portal configuration for Niri - https://github.com/niri-wm/niri/pull/3173/changes
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config = { 
      common = {
        # Force the use of GTK for the file chooser, screen cast and screenshot portals - https://github.com/niri-wm/niri/issues/702#issuecomment-2392079684
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
      };

      niri = {
        default = [ "gnome" "gtk" ];
      };
    };
  };

  # Enable Xwayland support
  programs.xwayland.enable = true;

  # Session variables for Niri
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
  };

  environment.variables = {
    # GTK 4.20 stopped handling dead keys and Compose on its own on Wayland. To make them work, either run an IME like IBus or Fcitx5, or set the GTK_IM_MODULE=simple environment variable.
    GTK_IM_MODULE = "simple";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # GTK theme configuration for consistent appearance
  programs.dconf.enable = true;
}
