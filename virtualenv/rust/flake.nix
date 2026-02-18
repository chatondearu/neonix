{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Uncomment for nightly toolchain:
    # rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Stable toolchain
            rustc
            cargo
            rustfmt
            clippy

            # LSP + DAP
            rust-analyzer
            lldb  # lldb-dap for helix debugger

            # Useful CLI tools
            cargo-watch   # cargo watch -x run
            cargo-expand  # expand macros
            cargo-audit   # security audit
          ];

          # rust-analyzer needs to know where the stdlib sources are
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

          shellHook = ''
            echo " Rust env — $(rustc --version) | $(cargo --version)"
          '';
        };
      });
}
