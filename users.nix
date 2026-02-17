# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.chaton = {
    isNormalUser = true;
    description = "Chaton";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "video"
      "input"
      "greeter"
    ];
    packages = with pkgs; [
      #thunderbird
      unstable.discord
      unstable.floorp-bin # Firefox fork
    ];
  };
  
  programs.firefox.enable = true;
}
