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
    ./system/system.nix
    ./system/security.nix
    ./system/debug.nix

    ./shells
  ];

  system.stateVersion = "25.11";
}
