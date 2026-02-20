{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    # Affinity v3 (Designer, Photo, Publisher unified app) via Wine
    # Repo: https://github.com/mrshmllow/affinity-nix
    # First launch: graphical installer appears — leave the install path default
    # Update: run `affinity-v3 update`
    inputs.affinity-nix.packages.${pkgs.stdenv.hostPlatform.system}.v3
  ] ++ (with pkgs; [
    # Blender
      unstable.blender
  ]);
}
