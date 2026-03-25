{
  description = "SSH, GPG, and GitHub CLI — tools use your default NixOS user dirs (~/.ssh, ~/.gnupg)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          openssh
          gnupg
          pinentry-curses
          git
          gh
        ];

        shellHook = ''
          export GPG_TTY="$(tty)"
          echo " SSH / GPG / gh — same keyrings as your login session:"
          echo "   SSH: $HOME/.ssh  |  GPG: $HOME/.gnupg"
          ${pkgs.openssh}/bin/ssh -V 2>&1 | head -n1
          echo "   $(gpg --version | head -n1)"
          echo "   $(gh --version | head -n1)"
          echo ""
          echo " Avoid: nix-shell --pure (can break pinentry/agent integration)."
        '';
      };
    });
}
