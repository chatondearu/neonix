{ lib, config, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = ["nix-command"];
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
}
