{ ... }:

### Special NixOS configuration for XR VR/AR devices
# see: https://github.com/nix-community/nixpkgs-xr

let
  nixpkgs-xr = import (builtins.fetchTarball "https://github.com/nix-community/nixpkgs-xr/archive/main.tar.gz");
in
{
  nixpkgs.overlays = [ nixpkgs-xr.overlays.default ];

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}