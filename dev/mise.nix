{
  pkgs,
  lib,
  ...
}: {
  # Mise: pin Node/Rust (etc.) per project without paying nix develop every time.
  # Stance: alongside Nix (ai-dev-kit ADR-013) — activate on PATH, not shim-primary.
  # gcc: rustup/mise-built crates need a host linker (NixOS has no /usr/bin/cc).
  environment.systemPackages = [
    pkgs.mise
    pkgs.gcc
  ];

  # Tool installs grow; keep them off the slow root SanDisk.
  environment.sessionVariables = {
    MISE_DATA_DIR = "/hdd/mise";
  };

  systemd.tmpfiles.rules = [
    "d /hdd/mise 0755 chaton users -"
  ];

  # Real binaries on PATH in interactive shells (agents: prefer this over shims).
  programs.fish.interactiveShellInit = lib.mkAfter ''
    if command -q mise
      mise activate fish | source
    end
  '';

  programs.zsh.interactiveShellInit = lib.mkAfter ''
    if command -v mise >/dev/null; then
      eval "$(mise activate zsh)"
    fi
  '';

  # Do NOT hook `mise direnv activate` — deprecated/unsupported with direnv
  # (https://mise.jdx.dev/direnv.html). Interactive shells use `mise activate`
  # above; project .envrc must not `use flake` (slow nix eval on every cd).
  # Non-interactive agents: `mise exec` / skill nix-develop-shell ladder.

  users.users.chaton.maid = {
    file.xdg_config."mise/config.toml".text = ''
      [settings]
      # Activate / mise exec — not shim-primary PATH (ADR-013).
      experimental = false
    '';
  };
}
