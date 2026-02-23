{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji liberation_ttf
    fira-code fira-code-symbols dina-font roboto lato montserrat
    raleway oswald merriweather poppins source-sans-pro league-spartan
  ];

  services.displayManager.autoLogin.enable = false;

  # Enable X11 for XWayland support (videoDrivers configured in system/gpu.nix)
  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
  };

  imports = [
    ./niri/niri.nix
  ];
}
