# /etc/nixos/modules/system/overlays.nix
# This module defines an overlay to add packages from nixpkgs-unstable.
{ inputs, config, ... }:

{
  nixpkgs.overlays = [
    (final: prev:
      let
        unstable-pkgs = import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config = config.nixpkgs.config;
        };
      in
      {
        unstable = unstable-pkgs; # Provides pkgs.unstable for convenience

        wivrn = unstable-pkgs.wivrn;

        # Dank Material Shell
        dms-shell = unstable-pkgs.dms-shell;
        dms-greeter = unstable-pkgs.dms-greeter;
        dgop = unstable-pkgs.dgop; # System monitoring widgets

        # Niri
        niri = unstable-pkgs.niri;
      })
  ];
}