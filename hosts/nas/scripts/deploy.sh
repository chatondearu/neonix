#!/usr/bin/env bash
# Deploy ./stacks/* to the Synology NAS and run docker compose up -d.
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
: "${NAS_REMOTE_STACKS_DIR:?NAS_REMOTE_STACKS_DIR}"

ssh_target="${NAS_USER}@${NAS_HOST}"
ssh_opts=(-p "$NAS_SSH_PORT" -o BatchMode=yes)

stack_filter="${NAS_STACK:-}"

rsync -az --delete \
  -e "ssh ${ssh_opts[*]}" \
  "$hosts_nas_root/stacks/" \
  "${ssh_target}:${NAS_REMOTE_STACKS_DIR}/"

remote_up() {
  local stack="$1"
  ssh "${ssh_opts[@]}" "$ssh_target" bash -s -- "$NAS_REMOTE_STACKS_DIR" "$stack" <<'REMOTE'
set -euo pipefail
base="$1"
stack="$2"
cd "$base/$stack"
if ! command -v docker >/dev/null; then
  echo "docker not found — run bootstrap on the NAS (see README)" >&2
  exit 1
fi
docker compose up -d --remove-orphans
REMOTE
}

if [[ -n "$stack_filter" ]]; then
  remote_up "$stack_filter"
else
  for dir in "$hosts_nas_root/stacks/"*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ -f "$dir/docker-compose.yml" || -f "$dir/compose.yml" ]] || continue
    echo "==> stack: $name"
    remote_up "$name"
  done
fi

echo "Deploy finished."
