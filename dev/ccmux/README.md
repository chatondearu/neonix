# ccmux configs — moved to ai-dev-kit

Source of truth: **`ai-dev-kit/aitools/templates/ccmux/`** (deployed by `cda.aitools.deploy` in `dev/aitools.nix`).

This directory is **deprecated**. After `nixos-rebuild switch`, configs live under `~/.config/ccmux/`.

To change agents or daemon settings, edit the template in the kit (or override `cda.aitools.ccmux.projectsRoot` on the host), then rebuild.

Mac: `bash ai-dev-kit/aitools/scripts/ccmux-align-mac.sh`
