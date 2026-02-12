# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ pkgs, ... }:

let
  # Import unstable for apps that need frequent updates like Discord
  pkgs-unstable = import <nixpkgs-unstable> {
    config.allowUnfree = true;
  };
in
{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.chaton = {
    isNormalUser = true;
    description = "Chaton";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
    ];
    packages = with pkgs; [
    #  thunderbird
    ] ++ [
      # Using unstable for frequent updates
      pkgs-unstable.discord
      pkgs-unstable.floorp-bin # Firefox fork
    ];
  };
  
  programs.firefox.enable = true;
}
