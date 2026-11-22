# Flake update — add neomind input (nixosModules.neomind)

## Metadata

- Date: 2026-11-22
- Author: worker r-e4t4m / neonix-23
- Branch: worker/r-e4t4m/neonix-23
- Rollback generation before update: unchanged (no switch in this PR)

## Inputs updated

- `neomind`: added, `git+ssh://git@github.com/chatondearu/neomind.git` @ `94d5244` (merged #212, `nixosModules.neomind`)
- `neomind/nixpkgs`: added (neomind flake nixpkgs-unstable pin)
- `nixpkgs` / `nixpkgs-unstable` / `dms` / `dms-plugin-registry` / `quickshell` / `nirinit`: unchanged

## Version/composition notes

- Stable base still on `nixos-26.05`: yes
- Unstable overlay scope changed: no
- Niri module source changed: no
- Quickshell drift status: unchanged

## Build and switch validation

- `nix flake check`: pass (local eval of `nixosConfigurations.neo-nix`)
- `sudo nixos-rebuild build --flake .#neo-nix`: not run (owner rebuild)
- `sudo nixos-rebuild switch --flake .#neo-nix`: not run (must not kill cargo live)
- `bash /home/chaton/etc/nixos/gaming/smoke-tests-wayland.sh`: not run

## Functional checks

- Greetd / Niri / DMS / portals / Sunshine / Steam / Wayland / XWayland: not run (config-only PR)
- Matrix reference used: no

## VR/gaming checks (when relevant)

- SteamVR / WiVRn / Gamescope: not tested

## Regressions observed

- None locally. GHA `nix flake check` may fail to fetch private `neomind` without SSH/token.
- Temporary workaround: owner eval/build as `chaton` (SSH), then switch
- Blocking severity: P2 (CI fetch), P0 none for host eval

## Decision

- Keep current lockfile: yes
- Rollback needed: no
- Follow-up tasks created: no

## Follow-up actions

- [ ] Owner: `sudo nixos-rebuild switch --flake .#neo-nix` then stop `run-live.sh`
- [ ] Optional: CI deploy key or GitHub token so GHA can fetch private neomind
