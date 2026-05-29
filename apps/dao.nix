{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.neo.dao;
in {
  options.neo.dao = {
    affinity.enable =
      lib.mkEnableOption "Affinity v3 (Wine prefix build; needs cache.garnix.io or long local build)"
      // {
        default = false;
        description = ''
          Installs affinity-v3 from affinity-nix. Binary cache entries on cache.garnix.io
          use short-lived signed URLs; when substitution fails, the Wine prefix build can fail
          in the Nix sandbox (winecfg without display). Enable only when you need Affinity on
          this system and substitution succeeds, or after `nix build` of affinity-v3 succeeds.
        '';
      };
  };

  config = {
    nixpkgs.overlays = [ inputs.affinity-nix.overlays.default ];

    environment.systemPackages =
      lib.optionals cfg.affinity.enable [
        pkgs.affinity-v3
      ]
      ++ (with pkgs; [
        unstable.blender
        onlyoffice-desktopeditors
      ]);
  };
}
