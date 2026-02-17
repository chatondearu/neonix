{ pkgs, ... }:

{
  # Zsh as system default shell
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    enableLsColors = true;
  };

  users.defaultUserShell = pkgs.zsh;
}
