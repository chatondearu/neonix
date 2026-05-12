{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    xwayland-satellite
    xwayland-run
  ];

  # XDG Portal configuration for Niri - https://github.com/niri-wm/niri/pull/3173/changes
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      # xdg-desktop-portal-wlr supprimé (incompatible Niri/Mutter API)
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config = {
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
      };
    };
  };

  # Enable Xwayland support
  programs.xwayland.enable = true;
}
