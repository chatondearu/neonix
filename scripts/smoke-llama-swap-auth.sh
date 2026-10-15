#!/usr/bin/env bash
set -euo pipefail

# Regression smoke (ADR-001): llama-swap on :9292 must reject unauthenticated API use.
# Wired from scripts/safe-flake-update.sh after the Wayland smoke.
#
# Unauthenticated path (default): curl /v1/models without a key → must be non-2xx.
# Positive path (optional): set LLAMA_SWAP_API_KEY then re-run this script, e.g.
#   LLAMA_SWAP_API_KEY=sk-... bash scripts/smoke-llama-swap-auth.sh
#   # or after switch: set -a; source /run/agenix/llama-swap-api-key; set +a
#   curl -sS -H "Authorization: Bearer $LLAMA_SWAP_API_KEY" http://127.0.0.1:9292/v1/models

host="${LLAMA_SWAP_HOST:-127.0.0.1}"
port="${LLAMA_SWAP_PORT:-9292}"
url="http://${host}:${port}/v1/models"
timeout_s="${LLAMA_SWAP_SMOKE_TIMEOUT:-3}"

ok() { printf '[OK] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }

echo '== llama-swap auth smoke =='

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

http_code="$(
  curl -sS -o "$tmp" -w '%{http_code}' -m "$timeout_s" "$url" 2>/dev/null \
    || true
)"

if [[ -z "$http_code" || "$http_code" == "000" ]]; then
  warn "llama-swap not reachable at $url (skip auth assert)"
  exit 0
fi

case "$http_code" in
  2*)
    fail "unauthenticated GET $url returned HTTP $http_code (auth required)"
    ;;
  *)
    ok "unauthenticated GET $url rejected (HTTP $http_code)"
    ;;
esac

if [[ -n "${LLAMA_SWAP_API_KEY:-}" ]]; then
  auth_code="$(
    curl -sS -o "$tmp" -w '%{http_code}' -m "$timeout_s" \
      -H "Authorization: Bearer ${LLAMA_SWAP_API_KEY}" \
      "$url" 2>/dev/null \
      || true
  )"
  case "$auth_code" in
    2*)
      ok "authenticated GET $url succeeded (HTTP $auth_code)"
      ;;
    *)
      fail "authenticated GET $url returned HTTP ${auth_code:-unreachable}"
      ;;
  esac
else
  warn "LLAMA_SWAP_API_KEY unset; skipping positive-path check"
fi

echo '== Done =='
