{ pkgs, ... }:
let
  secrets = import ./secrets.nix;
in
{

  environment.systemPackages = with pkgs; [
    cursor-cli
    code-cursor
    git
    gh
    lazygit
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
}