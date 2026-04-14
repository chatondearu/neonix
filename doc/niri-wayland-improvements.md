# Niri / Wayland Improvements and Automation Backlog

This document tracks safe improvements for the current NixOS + Niri + Wayland stack, with priority and rollout guidance.

## Current baseline

- Core system channel: `nixos-25.11` (`flake.nix`, `flake.lock`).
- Selected fast-moving desktop/gaming pieces come from unstable (`unstable.nix`, `desktop/niri/niri.nix`).
- Session chain: `greetd` -> `dms-greeter` -> `niri` -> `dms-shell`.

## Validated findings (P0/P1) with evidence

### P0 findings

1. **Version composition coupling is strong**
   - Evidence:
     - `flake.nix`: stable base (`nixpkgs.url = github:NixOS/nixpkgs/nixos-25.11`).
     - `desktop/niri/niri.nix`: stable module disabled, unstable Niri module imported.
     - `unstable.nix`: `niri`, `dms-*`, and `steam` sourced from unstable.
   - Why this matters:
     - Changes in unstable module/package interfaces can break login/session components.

2. **Session stack has several moving parts**
   - Evidence:
     - `desktop/niri/greeter.dank.nix`: greetd + dms-greeter + quickshell.
     - `desktop/niri/shell.dank.nix`: dms-shell systemd user integration.
   - Why this matters:
     - Greeter or shell regressions can block desktop access despite successful rebuild.

### P1 findings

1. **Two Quickshell revisions are present in lock graph**
   - Evidence:
     - `flake.lock`: both `quickshell` and `quickshell_2` nodes, with different revisions.
     - `dms` input depends on one Quickshell node while root input uses another.
   - Why this matters:
     - Drift can increase integration risk on `nix flake update`.

2. **Nirinit config source uses a local repo path**
   - Evidence:
     - `desktop/niri/niri.nix`: `{{home}}/etc/nixos/desktop/niri/nirinit/config.toml`.
   - Why this matters:
     - Portability is reduced when cloning the config elsewhere.

3. **Sunshine service scope can be confusing during operations**
   - Evidence:
     - Latest terminal output shows:
       - `systemctl restart sunshine` -> access denied
       - `sudo systemctl restart sunshine` -> unit not found
       - `systemctl --user restart sunshine` -> success
   - Source:
     - runtime terminal log in `.cursor/.../terminals/1.txt` (latest rebuild session trace).
   - Why this matters:
     - Wrong unit scope causes false alarms during troubleshooting.

## Safe action plan (do now, low regression risk)

1. **Documentation hardening (P0)**
   - Keep architecture and operational docs aligned with the real stack:
     - stable + targeted unstable model
     - Niri module override rationale
     - user-service operations for Sunshine

2. **Post-update smoke tests checklist (P0)**
   - Run after each `nix flake update` and rebuild:
     - greetd login
     - niri session startup
     - file chooser/screencast portals
     - `systemctl --user status sunshine`
     - Steam launch + one XWayland app + one Wayland app

3. **Quickshell drift visibility (P1)**
   - Add a release note in docs before each lock update to mention current Quickshell pair and test outcomes.

## Potential improvements (next iterations)

### Composition and versioning

- Evaluate pin alignment strategy for Quickshell across root and DMS dependency chains.
- Evaluate reducing unstable overlay surface (keep only packages that strictly require unstable).
- Add a compatibility matrix section in docs for `nixpkgs`, `nixpkgs-unstable`, `niri`, `dms`, and `quickshell`.

### Reliability and portability

- Migrate nirinit config source to a less host-path-coupled approach.
- Add a fallback profile doc entry for emergency login/session recovery.
- Add clear user vs system service troubleshooting matrix for desktop services.

### Automation

- Add a simple script (or documented command bundle) for post-rebuild smoke tests.
- Add CI checks:
  - `nix flake check`
  - `nix build .#nixosConfigurations.neo-nix.config.system.build.toplevel`
- Add a changelog section for lock update impact notes.

## Rollback and safety model

- Always test with build before switch when touching desktop/gaming stack.
- Keep rollback command documented and ready:
  - `sudo nixos-rebuild switch --rollback`
- For risky updates, prefer staged validation:
  1. evaluate/build
  2. switch
  3. run smoke tests
  4. rollback immediately if greetd/session regressions appear
