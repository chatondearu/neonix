{ pkgs, ... }:

{
  # Default Shell (zsh)
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
    neo-update-channel = "sudo nix-channel --update && neo-switch";
    neo-upgrade-channel = "sudo nix-channel --update && neo-switch --upgrade";
    neo-update = "sudo nix --extra-experimental-features flakes flake update";
    neo-switch = "sudo nixos-rebuild switch --flake .#neo-nix";

    # System maintenance
    neo-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    neo-check = "nix-channel --list && echo '\nUpdates available:' && nix-env -u --dry-run";
    neo-copy-last-debug = "journalctl -b -1 --no-pager &> ~/etc/nixos/journal.log";
  };
}