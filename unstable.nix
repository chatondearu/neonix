# This overlay intentionally keeps unstable exposure narrow.
# Rule: add only components that are justified by desktop/gaming compatibility.
# See doc/version-governance.md for update policy and validation routine.
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
        unstable = unstable-pkgs; # Provides pkgs.unstable for explicit opt-in usage

        # Dank Material Shell stack (paired with niri/quickshell integration)
        dms-shell = unstable-pkgs.dms-shell;
        dms-greeter = unstable-pkgs.dms-greeter;
        dgop = unstable-pkgs.dgop; # System monitoring widgets

        # Niri compositor and related module path in desktop/niri/niri.nix
        niri = unstable-pkgs.niri;

        # Steam remains unstable here for current VR/gaming behavior consistency.
        # Re-evaluate periodically with release notes + smoke tests.
        steam = unstable-pkgs.steam;
      })

      # Nixpkgs-XR - https://github.com/nix-community/nixpkgs-xr
      inputs.nixpkgs-xr.overlays.default
  ];
}