# Ghostty terminal — declarative config via nix-maid.
# themes/dankcolors is written by DMS dynamic theming; do not manage it here.
{self, ...}: {
  users.users.chaton.maid = {
    file.xdg_config."ghostty/config".source = "${self}/desktop/ghostty/config";
  };
}
