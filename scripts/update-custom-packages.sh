#!/usr/bin/env bash
set -euo pipefail

# Update pinned custom packages under pkgs/ and optionally flake.lock.
# Each package ships its own update.sh (see pkgs/packaging.md).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flake_ref="${FLAKE_REF:-.#neo-nix}"
update_packages=1
run_flake_update=1
dry_run=0
do_build=0

usage() {
  cat <<'EOF'
Usage: update-custom-packages.sh [options]

Updates custom package pins (sources.json, package-lock.json) then optionally
refreshes flake.lock. Does not run nixos-rebuild; use neo-safe-update after.

Options:
  --no-flake       Skip "nix flake update"
  --flake-only     Only run "nix flake update" (skip custom packages)
  --build          Run "nixos-rebuild build" after updates
  --dry-run        Print steps without changing files
  -h, --help       Show this help

Environment:
  FLAKE_REF        Flake attribute for --build (default: .#neo-nix)

Examples:
  bash scripts/update-custom-packages.sh
  bash scripts/update-custom-packages.sh --no-flake
  bash scripts/update-custom-packages.sh --flake-only
EOF
}

log() {
  printf '==> %s\n' "$*"
}

run_pkg_update() {
  local pkg_dir="$1"
  local pkg_name
  pkg_name="$(basename "$pkg_dir")"
  local update_script="$pkg_dir/update.sh"

  if [[ ! -f "$update_script" ]]; then
    printf '[WARN] No update.sh in %s, skipping\n' "$pkg_name" >&2
    return 0
  fi

  log "Updating $pkg_name"
  if (( dry_run )); then
    printf '    (dry-run) nix-shell %s/update.sh --run bash ./update.sh\n' "$pkg_dir"
    return 0
  fi

  (
    cd "$pkg_dir"
    nix-shell ./update.sh --run "bash ./update.sh"
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-flake)
      run_flake_update=0
      ;;
    --flake-only)
      update_packages=0
      ;;
    --build)
      do_build=1
      ;;
    --dry-run)
      dry_run=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

cd "$repo_root"

log "Repository: $repo_root"

if (( update_packages )); then
  run_pkg_update "$repo_root/pkgs/cursor"
  run_pkg_update "$repo_root/pkgs/opencode"
  run_pkg_update "$repo_root/pkgs/gitnexus"
  run_pkg_update "$repo_root/pkgs/OpenAgentsControl"
  run_pkg_update "$repo_root/pkgs/llama-swap"
  run_pkg_update "$repo_root/pkgs/ollama"
  run_pkg_update "$repo_root/pkgs/llama-cpp"
fi

if (( run_flake_update )); then
  log 'Updating flake.lock'
  if (( dry_run )); then
    printf '    (dry-run) nix flake update\n'
  else
    nix flake update
  fi
fi

if (( do_build )); then
  log "Building $flake_ref"
  if (( dry_run )); then
    printf '    (dry-run) nixos-rebuild build --flake %s\n' "$flake_ref"
  else
    sudo nixos-rebuild build --flake "$flake_ref"
  fi
fi

if (( dry_run )); then
  log 'Dry run finished (no files changed)'
else
  log 'Update finished'
  printf '\nNext steps:\n'
  printf '  git diff --stat\n'
  printf '  sudo nixos-rebuild switch --flake %s\n' "$flake_ref"
  printf '  bash scripts/safe-flake-update.sh   # update + build + switch + smoke tests\n'
fi
