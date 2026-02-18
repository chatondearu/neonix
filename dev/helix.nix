{ pkgs, ... }:

{
  users.users.chaton.maid = {
    file.xdg_config."helix/config.toml".source = "{{home}}/etc/nixos/dev/helix/config.toml";
    file.xdg_config."helix/languages.toml".source = "{{home}}/etc/nixos/dev/helix/languages.toml";
  };

  environment.systemPackages = with pkgs; [
    # Editor
    helix

    # Helix has no built-in terminal; zellij provides split panes
    # to run opencode + helix side-by-side (like Cursor's AI sidebar)
    zellij

    # --- LSP servers ---

    # TypeScript / JavaScript / Vue / Nuxt
    typescript
    typescript-language-server
    vue-language-server           # Volar (Vue 3 / Nuxt 3)
    vscode-langservers-extracted  # HTML, CSS, JSON, ESLint LSPs
    tailwindcss-language-server
    emmet-language-server
    prettierd                     # Fast prettier daemon for formatting

    # Rust
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # Nix
    nil                           # Nix LSP
    nixfmt-rfc-style              # Nix formatter

    # Config files
    taplo                         # TOML (Cargo.toml, pyproject.toml)
    yaml-language-server          # YAML (docker-compose, CI configs)
    marksman                      # Markdown

    # --- Debug adapters (DAP) ---
    lldb    # Rust / C / C++ debugging via lldb-dap
  ];
}
