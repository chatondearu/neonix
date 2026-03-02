{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs_22
    pnpm
    typescript
    typescript-language-server
    vue-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-language-server
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    lldb
    cargo-watch
    cargo-audit
    docker-compose
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    echo "󰡪  Full-stack env — node $(node --version) | $(rustc --version)"
  '';
}
