{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./fish.nix
  ];

  # Available shells
  environment = {
    shells = with pkgs; [fish zsh];
    pathsToLink = ["/share/fish" "/share/zsh"];
  };

  # Common shell aliases (applied to all shells)
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
    # Flake closure: reflects your real NixOS config (unlike nix-env -u which scans the user profile + huge nixpkgs).
    neo-check = "nix-channel --list && printf '\\n%s\\n' 'neo-nix closure (nix build --dry-run):' && nix build \"$HOME/etc/nixos#nixosConfigurations.neo-nix.config.system.build.toplevel\" --dry-run";
    neo-check-profile = "echo 'nix-env user profile (dry-run upgrade):' && nix-env -u --dry-run";
    neo-copy-last-debug = "journalctl -b -1 --no-pager &> ~/etc/nixos/journal.log";
  };
}
