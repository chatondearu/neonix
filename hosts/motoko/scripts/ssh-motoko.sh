#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

HOST="${MOTOKO_SSH_HOST:-motoko-prod}"
PORT="${MOTOKO_SSH_PORT:-2242}"
USER="${MOTOKO_SSH_USER:-root}"
IDENT="${MOTOKO_SSH_IDENTITY_FILE:-}"

ssh_args=(-p "$PORT" -o StrictHostKeyChecking=accept-new)
[[ -n "$IDENT" ]] && ssh_args+=(-i "$IDENT" -o IdentitiesOnly=yes)

exec ssh "${ssh_args[@]}" "${USER}@${HOST}" "$@"
