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

    # Flake-based system update workflow
    neo-update = "cd \"$HOME/etc/nixos\" && nix flake update";
    neo-build = "cd \"$HOME/etc/nixos\" && sudo nixos-rebuild build --flake .#neo-nix";
    neo-switch = "cd \"$HOME/etc/nixos\" && sudo nixos-rebuild switch --flake .#neo-nix";
    neo-safe-update = "bash \"$HOME/etc/nixos/scripts/safe-flake-update.sh\"";
    neo-rollback = "sudo nixos-rebuild switch --rollback";

    # Update release-note workflow
    neo-new-note = "bash \"$HOME/etc/nixos/scripts/new-flake-release-note.sh\"";
    neo-new-note-qs = "bash \"$HOME/etc/nixos/scripts/new-flake-release-note.sh\" quickshell-sync";

    # System maintenance
    neo-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    # Flake closure: reflects your real NixOS config (unlike nix-env -u which scans the user profile + huge nixpkgs).
    neo-check = "nix-channel --list && printf '\\n%s\\n' 'neo-nix closure (nix build --dry-run):' && nix build \"$HOME/etc/nixos#nixosConfigurations.neo-nix.config.system.build.toplevel\" --dry-run";
    neo-check-profile = "echo 'nix-env user profile (dry-run upgrade):' && nix-env -u --dry-run";
    neo-copy-last-debug = "journalctl -b -1 --no-pager &> ~/etc/nixos/journal.log";

    # Niri/Wayland validation helpers
    neo-smoke = "bash \"$HOME/etc/nixos/gaming/smoke-tests-wayland.sh\"";
    neo-test-matrix = "echo 'See: $HOME/etc/nixos/doc/test-matrix-wayland.md'";
  };
}
