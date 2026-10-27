#!/usr/bin/env bash
# Smoke SSH from neo-nix to Motoko (root, key-only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

HOST="${MOTOKO_SSH_HOST:-motoko-prod}"
PORT="${MOTOKO_SSH_PORT:-2242}"
USER="${MOTOKO_SSH_USER:-root}"
IDENT="${MOTOKO_SSH_IDENTITY_FILE:-}"

ssh_args=(-p "$PORT" -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
[[ -n "$IDENT" ]] && ssh_args+=(-i "$IDENT" -o IdentitiesOnly=yes)

echo "[smoke] ssh ${USER}@${HOST}:${PORT}"
ssh "${ssh_args[@]}" "${USER}@${HOST}" 'hostname; id -un; test -w /root && echo root_writable_ok'
echo "[smoke] OK"
