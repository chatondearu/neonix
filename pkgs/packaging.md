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
| `llama-swap` | GitHub release tarball | `nix-prefetch-url` (~seconds) |
| `ollama` | GitHub release `ollama-linux-amd64.tar.zst` | `nix-prefetch-url` (~seconds) |
| `llama-cpp` | nixpkgs CUDA build **or** CPU prebuilt `b*` ubuntu tarball | see `pkgs/llama-cpp/sources.json` |

### AI stack build cost (`dev/ai.nix`)

| Component | Cost | Notes |
|-----------|------|-------|
| `llama-cpp` (`nixpkgs-cuda`) | High compile | Only GPU path for `llama-server`; uses Hydra cache when possible |
| `llama-cpp` (`prebuilt-cpu`) | Fast | Official ubuntu binaries, **no CUDA** |
| `llama-swap`, `ollama`, `opencode` | Fast | Prebuilt releases |
| `faster-whisper` + `large-v3-turbo` + CUDA | High runtime | Service build + multi-GB model download |
| `piper` + CUDA | Medium | Voice model download at runtime |
| `openwakeword` | Low | |

Run all custom package updates from the repo root:

```bash
bash scripts/update-custom-packages.sh
```

Options: `--no-flake`, `--flake-only`, `--build`, `--dry-run` (see script `--help`).

Individual packages:

```bash
bash pkgs/cursor/update.sh
bash pkgs/opencode/update.sh
bash pkgs/gitnexus/update.sh
bash pkgs/OpenAgentsControl/update.sh
nix flake update
```