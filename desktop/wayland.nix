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
      xdg-desktop-portal-wlr # Wayland portal
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
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };

  # Enable Xwayland support
  programs.xwayland.enable = true;
}
