{ pkgs, ... }:

{
  # Shell (zsh)
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    enableLsColors = true;
  };
  users.defaultUserShell = pkgs.zsh;

  # Shell aliases
  environment.shellAliases = {
    neo-monado = "systemctl --user start monado.service";
  };
}
