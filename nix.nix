{ lib, config, pkgs, ... }:

{
  documentation.nixos.enable = false;

  nix = {
    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];

      # Limit build parallelism to prevent OOM during heavy builds
      max-jobs = 4;
      cores = 4;
      
      # Add niri cache to speed up builds
      substituters = [
        "https://cache.nixos.org"
        "https://niri.cachix.org"
        "https://nix-community.cachix.org"
        "https://comfyui.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      ];
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable nix-ld for dynamic linking
  programs.nix-ld.enable = true;

  # Enable nh for cleaner nix-store
  programs.nh = {
    enable = true;
    # clean.enable = true;
    # clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/chaton/etc/nixos"; # sets NH_OS_FLAKE variable for you
  };
}
