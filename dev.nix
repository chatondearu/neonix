{ pkgs, ... }:
let
  secrets = import ./secrets.nix;

  # Import unstable packages directly to avoid breaking binary cache
  pkgs-unstable = import <nixpkgs-unstable> {
    config.allowUnfree = true;
  };
in
{

  environment.systemPackages = with pkgs; [
    git
    gh
    lazygit
  ] ++ [
    # Unstable packages (imported separately to preserve binary cache)
    pkgs-unstable.cursor-cli
    pkgs-unstable.code-cursor
  ];

  programs.git = {
    enable = true;
    config = {
      user = {
        name  = secrets.githubUser;
        email = secrets.githubEmail;
      };
      init.defaultBranch = "main";
    };
  };

  virtualisation.docker.enable = true;
  programs.adb.enable = true;
}