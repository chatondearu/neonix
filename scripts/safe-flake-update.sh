#!/usr/bin/env bash
set -euo pipefail

# Safe update routine for this Niri/Wayland workstation.
# This script intentionally keeps steps explicit and aborts on first failure.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flake_ref="${FLAKE_REF:-.#neo-nix}"
smoke_script="$repo_root/gaming/smoke-tests-wayland.sh"

echo "== Safe flake update routine =="
echo "Repository: $repo_root"
echo "Flake ref: $flake_ref"

cd "$repo_root"

echo "--> Updating lockfile"
nix flake update

echo "--> Building system (no switch)"
sudo nixos-rebuild build --flake "$flake_ref"

echo "--> Switching system"
sudo nixos-rebuild switch --flake "$flake_ref"

if [[ -x "$smoke_script" ]]; then
  echo "--> Running smoke tests"
  bash "$smoke_script"
else
  echo "[WARN] Smoke test script missing or not executable: $smoke_script"
  echo "[WARN] Run manual checks before considering this update successful."
fi

echo "== Update routine completed =="
