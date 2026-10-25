#!/usr/bin/env bash
# One-time NAS setup: directories, Container Manager check, SSH-oriented hardening hints.
# Run from neo-nix: ./scripts/bootstrap-remote.sh  (reads ../.env)
set -euo pipefail

hosts_nas_root="${HOSTS_NAS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
env_file="${NAS_ENV_FILE:-$hosts_nas_root/.env}"

if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file — copy .env.example to .env" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$env_file"

: "${NAS_HOST:?NAS_HOST}"
: "${NAS_USER:?NAS_USER}"
NAS_SSH_PORT="${NAS_SSH_PORT:-22}"
NAS_REMOTE_STACKS_DIR="${NAS_REMOTE_STACKS_DIR:-/volume1/docker/stacks}"

ssh_target="${NAS_USER}@${NAS_HOST}"
ssh_opts=(-p "$NAS_SSH_PORT" -o BatchMode=yes)

ssh "${ssh_opts[@]}" "$ssh_target" bash -s -- "$NAS_REMOTE_STACKS_DIR" <<'REMOTE'
set -euo pipefail
stacks_dir="$1"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Bootstrap remote steps need root on the NAS (ssh as admin or use sudo)." >&2
  echo "Re-run: ssh admin@nas 'sudo bash -s' < scripts/bootstrap-on-nas.sh" >&2
  exit 1
fi

mkdir -p "$stacks_dir"
chmod 755 "$stacks_dir"

install_container_manager() {
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    echo "Docker already usable."
    return 0
  fi
  if ! command -v synopkg >/dev/null; then
    echo "synopkg not found — install Container Manager from DSM or upload the .spk manually." >&2
    return 1
  fi
  for pkg in ContainerManager Docker; do
    if synopkg status "$pkg" 2>/dev/null | grep -q '^Status: \[installed\]'; then
      echo "Package $pkg already installed."
      synopkg start "$pkg" || true
      return 0
    fi
  done
  echo "Installing Container Manager via synopkg (needs internet + valid DSM account)..."
  if synopkg install ContainerManager; then
    synopkg start ContainerManager
    return 0
  fi
  echo "synopkg install failed — download Container Manager .spk from Synology and run:" >&2
  echo "  synopkg install /path/to/ContainerManager-x64.spk" >&2
  return 1
}

install_container_manager

echo ""
echo "Manual DSM checks (no extra packages required):"
echo "  - Dedicated admin user for SSH; disable default 'admin' if still enabled"
echo "  - Control Panel → Security → Auto Block + firewall (allow LAN SSH + app ports only)"
echo "  - Control Panel → Terminal → SSH: key auth, consider non-default port"
echo "  - Optional CLI tools without Package Center: Entware (see README)"
echo ""
echo "Stacks directory: $stacks_dir"
REMOTE
