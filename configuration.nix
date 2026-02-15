# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./system/boot.nix
      ./hardware-configuration.nix
      ./system/network.nix
      ./system/gpu.nix
      ./system/system.nix
      ./system/security.nix
      ./system/devices.nix
      ./system/update-notifier.nix
      ./system/debug.nix
      ./nix.nix
      ./wm/default.nix
      ./gaming/default.nix
      ./stream.nix
      ./dev.nix
      ./zsh.nix
      ./users.nix
    ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # utils
    wget
    ghostty # Terminal emulator
    helix # Text editor in rust for the terminal
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
