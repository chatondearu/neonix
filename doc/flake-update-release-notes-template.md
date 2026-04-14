# Flake Update Release Notes Template

Use this template after each `nix flake update` to keep version-impact tracking explicit and reproducible.

## Metadata

- Date:
- Author:
- Branch:
- Rollback generation before update:

## Inputs updated

- `nixpkgs`:
- `nixpkgs-unstable`:
- `dms`:
- `dms-plugin-registry`:
- `quickshell` (root):
- `quickshell` (transitive via DMS):
- `nirinit`:

## Version/composition notes

- Stable base still on `nixos-25.11`: yes/no
- Unstable overlay scope changed: yes/no
- Niri module source changed (`disabledModules` + unstable import): yes/no
- Quickshell drift status:
  - Root revision:
  - DMS-linked revision:
  - Delta/risk comment:

## Build and switch validation

- `sudo nixos-rebuild build --flake .#neo-nix`: pass/fail
- `sudo nixos-rebuild switch --flake .#neo-nix`: pass/fail
- `bash /home/chaton/etc/nixos/gaming/smoke-tests-wayland.sh`: pass/fail

## Functional checks

- Greetd login: ok/fail
- Niri session startup: ok/fail
- DMS shell startup (`systemctl --user status dms`): ok/fail
- Portal status (`systemctl --user status xdg-desktop-portal`): ok/fail
- Sunshine user service (`systemctl --user status sunshine`): ok/fail
- Steam launch: ok/fail
- One Wayland-native app test: ok/fail
- One XWayland app test: ok/fail
- Matrix reference used: `doc/test-matrix-wayland.md` yes/no

## VR/gaming checks (when relevant)

- SteamVR launch: ok/fail/not tested
- WiVRn status: ok/fail/not tested
- Gamescope test: ok/fail/not tested

## Regressions observed

- None / list:
- Temporary workaround:
- Blocking severity (P0/P1/P2):

## Decision

- Keep current lockfile: yes/no
- Rollback needed: yes/no
- Follow-up tasks created: yes/no

## Follow-up actions

- [ ] Update `doc/niri-wayland-improvements.md` if new long-term issue appears
- [ ] Add targeted fix PR/change
- [ ] Re-run smoke tests after fix
