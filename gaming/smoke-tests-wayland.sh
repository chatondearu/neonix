#!/usr/bin/env bash
set -euo pipefail

# Lightweight post-rebuild checks for the Niri/Wayland desktop stack.
# This script is intentionally read-only and does not restart services.

ok() {
  printf '[OK] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "Command available: $1"
  else
    warn "Command missing: $1"
  fi
}

echo '== Niri/Wayland smoke tests =='

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
  ok "Session type is wayland"
else
  warn "Session type is not wayland (XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset})"
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == "niri" ]]; then
  ok "Desktop is niri"
else
  warn "Desktop is not niri (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})"
fi

check_cmd systemctl
check_cmd steam
check_cmd fuzzel
check_cmd xdg-open

if systemctl --user is-active --quiet sunshine; then
  ok "Sunshine user service is active"
else
  warn "Sunshine user service is not active"
fi

if systemctl --user is-active --quiet dms.service; then
  ok "DMS shell user service is active"
else
  warn "DMS shell user service is not active"
fi

if systemctl --user is-active --quiet xdg-desktop-portal.service; then
  ok "XDG desktop portal user service is active"
else
  warn "XDG desktop portal user service is not active"
fi

if command -v niri >/dev/null 2>&1; then
  ok "niri binary available"
else
  warn "niri binary not found in PATH"
fi

echo '== Done =='
