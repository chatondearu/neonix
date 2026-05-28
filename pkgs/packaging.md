To see what is inside a .deb before installing it in nixos :

```bash
nix-shell -p dpkg
dpkg -c ./application-name.deb
```

## Custom packages update strategy

| Package | Source | `update.sh` |
|---------|--------|-------------|
| `cursor` | Cursor API (AppImage) | `nix-prefetch-url` (~seconds) |
| `opencode` | GitHub release `opencode-linux-x64.tar.gz` | `nix-prefetch-url` (~seconds) |
| `gitnexus` | npm tarball + GitHub `package-lock.json` | `nix-prefetch-url` + `prefetch-npm-deps` (~seconds) |
| `OpenAgentsControl` | GitHub release `install.sh` | `nix-prefetch-url` (~seconds) |

Run updates from the repo root:

```bash
bash pkgs/cursor/update.sh
bash pkgs/opencode/update.sh
bash pkgs/gitnexus/update.sh
bash pkgs/OpenAgentsControl/update.sh
nix flake update
```