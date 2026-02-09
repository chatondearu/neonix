{ pkgs, ... }:

{
  # Enable Plasma 
  services.desktopManager.plasma6.enable = true;

  # Default display manager for Plasma
  services.displayManager.sddm = {
    enable = true;
  
  # To use Wayland (Experimental for SDDM)
    wayland.enable = true;
    settings.General.DisplayServer = "wayland";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];
}
