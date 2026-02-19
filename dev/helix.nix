{ pkgs, ... }:

{
  users.users.chaton.maid = {
    file.xdg_config."helix/config.toml".source = "{{home}}/etc/nixos/dev/helix/config.toml";
    file.xdg_config."helix/languages.toml".source = "{{home}}/etc/nixos/dev/helix/languages.toml";
  };

  environment.systemPackages = with pkgs; [
    # Editor + shell integration
    helix

    # Split panes to run opencode + helix side-by-side
    zellij

    # --- Global LSP servers (always needed regardless of project type) ---

    # Nix (system config, flakes, shell.nix)
    nil
    nixfmt-rfc-style

    # Config files common to all projects
    taplo               # TOML (Cargo.toml, flake.nix, pyproject.toml)
    yaml-language-server
    marksman            # Markdown

    # Generic formatter (used as fallback)
    prettierd
  ];
}
