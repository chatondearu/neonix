{
  lib,
  config,
  pkgs,
  ...
}: {
  documentation.nixos.enable = false;

  nix = {
    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      warn-dirty = false;
      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = 524288000; # 500MB

      # Limit build parallelism to prevent OOM during heavy builds
      max-jobs = 4;
      cores = 4;

      # Add niri cache to speed up builds
      substituters = [
        "https://cache.nixos.org"
        "https://cache.nixos-cuda.org"
        "https://niri.cachix.org"
        "https://nix-community.cachix.org"
        "https://comfyui.cachix.org"
        # Pre-built aarch64 packages for Raspberry Pi NixOS images (pi-sound, etc.)
        "https://nixos-raspberrypi.cachix.org"
        # garnix cache: pre-built Affinity Wine packages (avoids compiling Wine from scratch)
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];

      # Required for flake `nixConfig` substituters to apply when building as a normal user
      trusted-users = ["root" "chaton"];
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
