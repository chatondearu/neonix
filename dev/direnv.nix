{ pkgs, ... }:

{
  # direnv: auto-load dev environments per directory
  # nix-direnv: fast nix integration (caches the shell, no reload on every cd)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Hook direnv into fish
  programs.fish.interactiveShellInit = ''
    direnv hook fish | source
  '';
}
