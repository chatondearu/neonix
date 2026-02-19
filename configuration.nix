{ config, pkgs, ... }:

{
  imports = [
    # Core
    ./nix.nix
    ./unstable.nix
    ./hardware-configuration.nix
    ./users.nix

    # System
    ./system/boot.nix
    ./system/locale.nix
    ./system/network.nix
    ./system/gpu.nix
    ./system/system.nix
    ./system/security.nix
    ./system/devices.nix
    ./system/update-notifier.nix
    ./system/debug.nix

    # Desktop environment
    ./desktop/default.nix
    ./shells

    # Development
    ./dev/default.nix

    # Gaming
    ./gaming/default.nix

    # User applications
    ./apps/browsers.nix
    ./apps/streaming.nix
    ./apps/dao.nix
  ];

  # Enable AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  system.stateVersion = "25.11";
}
