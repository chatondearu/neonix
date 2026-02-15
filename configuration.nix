# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./nix.nix
      ./unstable.nix
      ./system/boot.nix
      ./system/locale.nix
      ./hardware-configuration.nix
      ./system/network.nix
      ./system/gpu.nix
      ./system/system.nix
      ./system/security.nix
      ./system/devices.nix
      ./system/update-notifier.nix
      ./system/debug.nix
      ./wm/default.nix
      ./gaming/default.nix
      ./stream.nix
      ./dev.nix
      ./zsh.nix
      ./users.nix
    ];

  # Enable AppImage
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
