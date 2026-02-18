{
  description = "Vue / Nuxt development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Runtime
            nodejs_22
            pnpm

            # LSP servers (activate helix language support on cd)
            typescript
            typescript-language-server
            vue-language-server          # Volar (Vue 3 / Nuxt 3)
            vscode-langservers-extracted # HTML, CSS, JSON, ESLint LSPs
            tailwindcss-language-server
            emmet-language-server
          ];

          shellHook = ''
            echo "󰡪 Vue/Nuxt env — node $(node --version) | pnpm $(pnpm --version)"
          '';
        };
      });
}
