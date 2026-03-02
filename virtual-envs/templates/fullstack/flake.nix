{
  description = "Full-stack development environment (Vue/Nuxt frontend + Rust backend)";

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
            # --- Frontend (Vue / Nuxt) ---
            nodejs_22
            pnpm
            typescript
            typescript-language-server
            vue-language-server
            vscode-langservers-extracted
            tailwindcss-language-server
            emmet-language-server

            # --- Backend (Rust) ---
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
            lldb
            cargo-watch
            cargo-audit

            # --- Shared tooling ---
            docker-compose
          ];

          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

          shellHook = ''
            echo "󰡪  Full-stack env"
            echo "  node $(node --version) | pnpm $(pnpm --version)"
            echo "  $(rustc --version)"
          '';
        };
      });
}
