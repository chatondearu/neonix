# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./system/boot.nix
      ./hardware-configuration.nix
      ./system/network.nix
      ./system/gpu-2.nix
      ./system/system.nix
      ./system/devices.nix
      ./system/update-notifier.nix
      ./envs/default.nix
      ./envs/desktop-plasma.nix
      ./gaming.nix
      ./stream.nix
      ./dev.nix
      ./zsh.nix
      ./users.nix
    ];
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # utils
    wget
    ghostty
    vlc

    # disk utilities
    kdePackages.partitionmanager
    testdisk
    exfat
    exfatprogs

    # zip utilities
    zip
    unzip
    p7zip
    rar
    unrar
    gzip
    xz

    # apps
    pciutils
    usbutils
    ffmpeg
    ffmpegthumbnailer
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
