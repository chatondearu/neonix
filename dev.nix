{ pkgs, ... }:

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
        name  = "chatondearu";
        email = "823314+chatondearu@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };
  };
}