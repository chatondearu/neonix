# /etc/nixos/modules/system/overlays.nix
# This module defines an overlay to add packages from nixpkgs-unstable.
{ inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev:
      let
        unstable-pkgs = import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          # Config is inherited from the top-level nixpkgs configuration
        };
      in
      {
        unstable = unstable-pkgs; # Provides pkgs.unstable for convenience
      })
  ];
}