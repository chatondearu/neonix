# Thin wrapper so `nix-shell` uses the same dev shell as `nix develop`.
(builtins.getFlake (toString ./.)).devShells.${builtins.currentSystem}.default
