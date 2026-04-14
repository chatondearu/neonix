# Version Governance (NixOS / Niri / Wayland)

This document defines how versions are managed to balance stability and feature freshness.

## Current policy

- Stable base: `nixos-25.11` (`nixpkgs` input).
- Targeted unstable surface:
  - `niri`
  - `dms-shell`
  - `dms-greeter`
  - `dgop`
  - `steam`

Any new unstable package must be justified in release notes and validated with smoke tests.

## Quickshell strategy

Current state: the lock graph may contain separate Quickshell revisions (root and DMS transitive).

Decision for now:
- Use **controlled tolerance** instead of forced immediate pin unification.
- Validate both revisions together through post-update checks.
- Only attempt hard alignment when:
  1. DMS compatibility for the target revision is confirmed.
  2. A rollback-ready update window is available.

Why:
- Forced pin alignment can break DMS unexpectedly if upstream compatibility lags.
- Controlled tolerance reduces surprise while preserving operational safety.

## Unstable surface review checklist

Run this review at each lock update:

1. Confirm `unstable.nix` still only exports justified packages.
2. For each unstable package, note why stable is not sufficient.
3. Run:
   - `sudo nixos-rebuild build --flake .#neo-nix`
   - `sudo nixos-rebuild switch --flake .#neo-nix`
   - `bash /home/chaton/etc/nixos/gaming/smoke-tests-wayland.sh`
4. Record result in `doc/flake-update-release-notes-template.md`.

## Exit criteria to move a package back to stable

- Stable channel provides required functionality.
- No regression in gaming/VR/session workflow in two consecutive update cycles.
- Release notes include tested evidence and rollback plan.
