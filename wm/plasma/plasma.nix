{ pkgs, lib, ... }:

{
  # Enable Plasma 
  services.desktopManager.plasma6.enable = true;

  # Default display manager for Plasma
  services.displayManager.sddm = {
    enable = true;
  
    # To use Wayland (Experimental for SDDM)
    wayland.enable = false; # TEST: disable wayland for sddm because we use niri, and it's not working with wayland
    #settings.General.DisplayServer = "wayland"; # TEST: enable wayland for sddm if niri is not working with wayland
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];

  # XDG Portal for Plasma (with lower priority so niri can override)
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = lib.mkDefault "kde";
  };
}
