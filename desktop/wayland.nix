{pkgs, lib, ...}: {
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

  # Portal GTK/GNOME backends need a live Wayland display; starting them with the
  # generic user session races niri startup and spams "cannot open display".
  systemd.user.services.xdg-desktop-portal-gtk = {
    unitConfig.After = lib.mkAfter ["graphical-session.target"];
    unitConfig.BindsTo = ["graphical-session.target"];
    unitConfig.PartOf = ["graphical-session.target"];
  };
  systemd.user.services.xdg-desktop-portal-gnome = {
    unitConfig.After = lib.mkAfter ["graphical-session.target"];
    unitConfig.BindsTo = ["graphical-session.target"];
    unitConfig.PartOf = ["graphical-session.target"];
  };
}
