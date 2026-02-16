{ pkgs, ... }:

{
  imports =
    [
      ./niri/niri.nix
    ];

  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji liberation_ttf
    fira-code fira-code-symbols dina-font roboto lato montserrat
    raleway oswald merriweather poppins source-sans-pro league-spartan
  ];

  services.displayManager.autoLogin.enable = false;

  # Set the default session to niri
  #services.displayManager.defaultSession = "niri";

  # Enable the X11 windowing system specifically for Nvidia Driver and steam
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    excludePackages = [ pkgs.xterm ];
  };
}
