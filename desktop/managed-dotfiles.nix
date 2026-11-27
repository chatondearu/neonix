# User dotfiles deployed with nix-maid (see also per-domain modules).
#
# | Path under ~/.config | Module |
# | -------------------- | ------ |
# | ghostty/config       | desktop/ghostty.nix (themes/ → DMS) |
# | fuzzel/fuzzel.ini    | desktop/fuzzel.nix |
# | niri/*.kdl           | desktop/niri.nix |
# | nirinit/config.toml  | desktop/niri.nix |
# | DankMaterialShell/*  | desktop/shell.dank.nix (not settings.json) |
# | helix/*              | dev/helix.nix |
# | opencode/opencode.json | dev/ai.nix |
# | agent skills         | dev/aitools.nix → kit nix/maid.nix (flake input, ADR-005) |
# | .tmux.conf, cda-aitools, cdamux | dev/aitools.nix → ai-dev-kit aitools/templates |
# | cdamuxd (systemd)              | ai-dev-kit cda.aitools module |
# | openvr, openxr, wivrn | gaming/steam.nix, gaming/vr/… |
#
# Add new apps here as desktop/<app>.nix + import below.
{...}: {
  imports = [
    ./ghostty.nix
    ./fuzzel.nix
  ];
}
