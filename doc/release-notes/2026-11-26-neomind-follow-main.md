# Flake update — neomind follow GitHub main (canary)

## Metadata

- Date: 2026-11-26
- Author: worker r-15wxz / neonix-follow-canary
- Branch: worker/r-15wxz/neonix-follow-canary
- Rollback generation before update: unchanged (sudo switch blocked in worker; owner must switch)

## Inputs updated

- `neomind`: `b18b99d` → `86b502f` (`refs/heads/main`, revCount 346 → 428)
- `nixpkgs` / `nixpkgs-unstable` / `dms` / `dms-plugin-registry` / `quickshell` / `nirinit`: unchanged

## Version/composition notes

- Stable base still on `nixos-26.05`: yes
- Unstable overlay scope changed: no
- Niri module source changed: no
- Quickshell drift status: unchanged
- Channel stays **canary** (`NEOMIND_CHANNEL`). A later GitHub `v*` must not auto-flip this host to prod.

## Build and switch validation

- `nix flake check`: not run (private neomind fetch on GHA)
- `nixos-rebuild build --flake .#neo-nix`: pass → `/nix/store/qqdk6gn4gnvfyj0mxdbyl2mqr46pgr0q-nixos-system-neo-nix-26.05.20261021.da6dc0e`
- `sudo nixos-rebuild switch --flake .#neo-nix`: not run (worker sudo not setuid; owner must)
- `bash /home/chaton/etc/nixos/gaming/smoke-tests-wayland.sh`: not run

## Functional checks

- Greetd / Niri / DMS / portals / Sunshine / Steam / Wayland / XWayland: not run (lock-only PR)
- Matrix reference used: no

## VR/gaming checks (when relevant)

- SteamVR / WiVRn / Gamescope: not tested

## Regressions observed

- None locally. Package name in the closure is still `neomind-desktop-0.3.1` (Cargo crate version); git rev is `86b502f` in the lock.
- GHA `nix flake check` may fail to fetch private `neomind` without SSH/token.
- Blocking severity: P2 (CI fetch), P0 none for host build

## Decision

- Keep current lockfile: yes
- Rollback needed: no
- Follow-up tasks created: no

## Follow-up actions

- [ ] Owner: `sudo nixos-rebuild switch --flake /home/chaton/.local/state/cdamux/worktrees/r-15wxz/neonix-follow-canary#neo-nix`
- [ ] Then stop cargo `run-live` so only systemd `neomind` owns `ask.sock`
- [ ] Confirm `neomind status` channel canary; ask ping=pong; no `/pair`
