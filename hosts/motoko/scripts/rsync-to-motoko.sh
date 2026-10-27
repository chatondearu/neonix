#!/usr/bin/env bash
# Rsync local motoko-ops checkout to Motoko:/opt/motoko (root on server).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a

HOST="${MOTOKO_SSH_HOST:-motoko-prod}"
PORT="${MOTOKO_SSH_PORT:-2242}"
USER="${MOTOKO_SSH_USER:-root}"
IDENT="${MOTOKO_SSH_IDENTITY_FILE:-}"
SRC="${MOTOKO_OPS_LOCAL:-/hdd/dev/neomatix/motoko-ops}"
DEST="${MOTOKO_OPS_ROOT:-/opt/motoko}"

[[ -d "$SRC" ]] || { echo "missing checkout: $SRC" >&2; exit 1; }

ssh_e="ssh -p ${PORT} -o StrictHostKeyChecking=accept-new"
[[ -n "$IDENT" ]] && ssh_e="$ssh_e -i $IDENT -o IdentitiesOnly=yes"

"$ROOT/scripts/ssh-motoko.sh" "mkdir -p ${DEST}"
rsync -az --delete \
  --exclude .git \
  --exclude .cursor \
  -e "$ssh_e" \
  "${SRC}/" "${USER}@${HOST}:${DEST}/"

echo "[rsync] synced ${SRC} → ${USER}@${HOST}:${DEST}"
