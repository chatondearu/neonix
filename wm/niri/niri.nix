{ pkgs, lib, ... }:

{
  # Enable niri compositor
  programs.niri.enable = true;

  # Essential Wayland packages for niri
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    xwayland-run

    waybar # Status bar (simple and lightweight)
    fuzzel # Application launcher (simpler than anyrun)
    grim # Screenshot tool
    slurp # Screenshot tool
    wl-clipboard # Clipboard manager
    wlsunset # Screen color temperature
    thunar # File manager recommendation
    mako # Notification daemon
  ];

  # Configure XDG Portal for niri (overrides Plasma's default)
  # xdg.portal = {
  #   enable = true;
  #   xdgOpenUsePortal = true;
  #   extraPortals = [ 
  #     pkgs.xdg-desktop-portal-gtk
  #     pkgs.kdePackages.xdg-desktop-portal-kde  # Keep KDE portal for compatibility
  #   ];
  #   config = {
  #     common.default = lib.mkForce [ "gtk" ];  # Force gtk as default
  #     niri.default = [ "gtk" "kde" ];
  #   };
  # };

  programs.xwayland.enable = true;

  # Session Variables
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "KDE";
    XDG_SESSION_DESKTOP = "niri";
    WAYLAND_DISPLAY = "wayland-0";
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Optional: waybar systemd service
  # You can configure waybar in ~/.config/waybar/

  home.file.".config/niri/config.kdl" = { source = ./config.kdl; };
}
