#!/usr/bin/env bash
# Run on macOS to replace Homebrew core ccmux (epilande) with skzv/tap/ccmux (same as neo-nix).
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CCMUX_DIR="$REPO_ROOT/dev/ccmux"

command -v brew >/dev/null || {
  echo "Homebrew is required." >&2
  exit 1
}

echo "==> Removing Homebrew core ccmux (epilande) if present"
if brew list --formula ccmux &>/dev/null; then
  brew uninstall ccmux
fi

echo "==> Installing skzv/tap/ccmux"
brew tap skzv/tap 2>/dev/null || true
if brew trust --help &>/dev/null; then
  brew trust --tap skzv/tap 2>/dev/null || true
fi
brew install skzv/tap/ccmux

echo "==> Syncing config from $CCMUX_DIR"
mkdir -p "$HOME/.config/ccmux"
cp "$CCMUX_DIR/ccmux.json" "$HOME/.config/ccmux/ccmux.json"
cp "$CCMUX_DIR/config.toml" "$HOME/.config/ccmux/config.toml"

if grep -q 'root = "/hdd/dev"' "$HOME/.config/ccmux/config.toml" 2>/dev/null; then
  echo ""
  echo "Note: projects.root is /hdd/dev (neo-nix). On Mac, edit:"
  echo "  \$HOME/.config/ccmux/config.toml"
  echo "  e.g. projects.root = \"\$HOME/dev\" or your usual dev path."
fi

echo "==> ccmux setup (hooks + daemon)"
ccmux setup

echo ""
echo "Done. Version: $(ccmux --version)"
echo "Optional: ccmux daemon install && ccmux daemon restart"
echo "Copy tmux binds from ai-dev-kit aitools/templates/tmux.conf into ~/.tmux.conf"
