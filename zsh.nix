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
    # VR
    neo-monado = "systemctl --user start monado.service";
    
    # System updates
    neo-update = "sudo nix-channel --update && sudo nixos-rebuild switch";
    neo-upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch --upgrade";
    neo-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    neo-check = "nix-channel --list && echo '\nUpdates available:' && nix-env -u --dry-run";
  };
}
