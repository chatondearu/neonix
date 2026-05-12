# oc-launch - deploy per-game OpenComposite override files just in time.
#
# Source for writeShellApplication; the wrapper provides shebang and
# `set -euo pipefail`.

GAMES_ROOT="${OC_LAUNCH_GAMES_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/opencomposite-games}"
GLOBAL_INI="${OC_LAUNCH_GLOBAL_INI:-${XDG_CONFIG_HOME:-$HOME/.config}/opencomposite/global/opencomposite.ini}"
LOG_ROOT="${OC_LAUNCH_LOG_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/oc-launch}"
BAK_SUFFIX=".oclaunch-bak"

print_help() {
  cat <<'EOF'
oc-launch - deploy per-game OpenComposite override files just in time.

Usage as a Steam launch option:
  oc-launch %command%

Subcommands:
  oc-launch list                  list configured games
  oc-launch status <appid>        show tracked files for a game
  oc-launch restore <appid>       restore originals from .oclaunch-bak
  oc-launch --dry-run %command%   print what would be deployed, run nothing
  oc-launch help                  show this help

Per-game overrides live in:
  $XDG_CONFIG_HOME/opencomposite-games/<appid>[-<slug>]/

Global tunables (fallback when a per-game directory has no opencomposite.ini):
  $XDG_CONFIG_HOME/opencomposite/global/opencomposite.ini

Both paths are managed by nix-maid via gaming/vr/opencomposite/default.nix.
EOF
}

# Find the first directory matching <appid> or <appid>-* in GAMES_ROOT.
# Uses `find -L` so symlinked entries (nix-maid deploys symlinks) are followed.
find_src_dir() {
  local appid="$1"
  local exact="$GAMES_ROOT/$appid"
  if [[ -d "$exact" ]]; then
    printf '%s\n' "$exact"
    return 0
  fi
  if [[ ! -d "$GAMES_ROOT" ]]; then
    printf ''
    return 0
  fi
  local match
  match="$(find -L "$GAMES_ROOT" -mindepth 1 -maxdepth 1 -type d -name "${appid}-*" 2>/dev/null | sort | head -n1)"
  printf '%s\n' "$match"
}

resolve_install_dir() {
  if [[ -n "${STEAM_COMPAT_INSTALL_PATH:-}" && -d "${STEAM_COMPAT_INSTALL_PATH}" ]]; then
    printf '%s\n' "$STEAM_COMPAT_INSTALL_PATH"
    return 0
  fi
  printf '%s\n' "$PWD"
}

resolve_appid() {
  printf '%s\n' "${SteamAppId:-${STEAM_APP_ID:-${SteamGameId:-unknown}}}"
}

ensure_log_file() {
  local appid="$1"
  mkdir -p "$LOG_ROOT"
  printf '%s\n' "$LOG_ROOT/${appid}-$(date +%Y%m%d-%H%M%S).log"
}

# deploy_file <src> <dest_dir> <log>
# Backs up an existing destination once, then copies <src> over it. Honors
# DRY_RUN=1 to print actions only.
deploy_file() {
  local src="$1"
  local dest_dir="$2"
  local log="$3"
  local name
  name="$(basename -- "$src")"
  local dest="$dest_dir/$name"
  local bak="${dest}${BAK_SUFFIX}"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    if [[ -f "$dest" && ! -f "$bak" ]]; then
      printf '[oc-launch] (dry-run) would back up %s -> %s\n' "$dest" "$bak" | tee -a "$log"
    fi
    printf '[oc-launch] (dry-run) would deploy %s -> %s\n' "$src" "$dest" | tee -a "$log"
    return 0
  fi

  if [[ -f "$dest" && ! -f "$bak" ]]; then
    if cp -f -- "$dest" "$bak"; then
      printf '[oc-launch] backed up %s\n' "$dest" >>"$log"
    else
      printf '[oc-launch] WARNING: could not back up %s\n' "$dest" >>"$log"
    fi
  fi

  if cp -f -- "$src" "$dest"; then
    printf '[oc-launch] deployed %s -> %s\n' "$name" "$dest" >>"$log"
  else
    printf '[oc-launch] ERROR: failed to deploy %s -> %s\n' "$name" "$dest" >>"$log"
    return 1
  fi
}

cmd_list() {
  if [[ ! -d "$GAMES_ROOT" ]]; then
    echo "No games configured (missing $GAMES_ROOT)."
    return 0
  fi
  local found=0
  local d base
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    base="$(basename -- "$d")"
    [[ "$base" == "_template" ]] && continue
    printf '%s\n' "$base"
    found=1
  done < <(find -L "$GAMES_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  if [[ "$found" -eq 0 ]]; then
    echo "No games configured."
  fi
}

cmd_status() {
  local appid="${1:-}"
  if [[ -z "$appid" ]]; then
    echo "usage: oc-launch status <appid>" >&2
    return 2
  fi
  local src
  src="$(find_src_dir "$appid")"
  if [[ -z "$src" ]]; then
    echo "No override directory found for appid $appid in $GAMES_ROOT." >&2
    return 1
  fi
  printf 'Override source: %s\n' "$src"
  echo "Tracked files:"
  local f name
  for f in "$src"/*; do
    [[ -f "$f" ]] || continue
    name="$(basename -- "$f")"
    printf '  - %s\n' "$name"
  done
  echo
  echo "Last deployment logs:"
  if [[ -d "$LOG_ROOT" ]]; then
    find "$LOG_ROOT" -maxdepth 1 -type f -name "${appid}-*.log" 2>/dev/null \
      | sort | tail -n3 | sed 's/^/  /'
  fi
}

cmd_restore() {
  local appid="${1:-}"
  if [[ -z "$appid" ]]; then
    echo "usage: oc-launch restore <appid>" >&2
    return 2
  fi
  local install_dir="${OC_LAUNCH_INSTALL_DIR:-}"
  if [[ -z "$install_dir" ]]; then
    local log
    log="$(find "$LOG_ROOT" -maxdepth 1 -type f -name "${appid}-*.log" 2>/dev/null \
      | sort | tail -n1)"
    if [[ -z "$log" ]]; then
      echo "No log file found for appid $appid; install dir is unknown." >&2
      echo "Hint: run the game once with oc-launch, or pass OC_LAUNCH_INSTALL_DIR=<path>." >&2
      return 1
    fi
    install_dir="$(grep -oE 'deployed [^ ]+ -> [^ ]+' "$log" | tail -n1 | awk '{print $NF}' | xargs -r dirname || true)"
  fi
  if [[ -z "$install_dir" || ! -d "$install_dir" ]]; then
    echo "Could not determine install directory for appid $appid." >&2
    return 1
  fi
  echo "Restoring backups in $install_dir..."
  local restored=0
  local bak target
  for bak in "$install_dir"/*"$BAK_SUFFIX"; do
    [[ -f "$bak" ]] || continue
    target="${bak%"${BAK_SUFFIX}"}"
    if mv -f -- "$bak" "$target"; then
      printf '  restored %s\n' "$target"
      restored=$((restored + 1))
    else
      printf '  ERROR: could not restore %s\n' "$target" >&2
    fi
  done
  echo "Done. Restored $restored file(s)."
}

run_wrapper() {
  local install_dir appid src_dir log
  install_dir="$(resolve_install_dir)"
  appid="$(resolve_appid)"
  log="$(ensure_log_file "$appid")"

  {
    printf '[oc-launch] appid=%s install_dir=%s pwd=%s dry_run=%s\n' \
      "$appid" "$install_dir" "$PWD" "${DRY_RUN:-0}"
    printf '[oc-launch] command: %s\n' "$*"
  } >>"$log"

  src_dir="$(find_src_dir "$appid")"
  if [[ -z "$src_dir" ]]; then
    printf '[oc-launch] no per-game override for appid=%s, passthrough.\n' "$appid" >>"$log"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      printf '[oc-launch] (dry-run) would exec: %s\n' "$*"
      return 0
    fi
    if [[ $# -eq 0 ]]; then
      return 0
    fi
    exec "$@"
  fi

  printf '[oc-launch] using override dir %s\n' "$src_dir" >>"$log"

  local has_local_ini=0
  local f name
  for f in "$src_dir"/*; do
    [[ -f "$f" ]] || continue
    name="$(basename -- "$f")"
    case "$name" in
      NOTES.md | README.md | README | *.bak | .*)
        continue
        ;;
    esac
    if [[ "$name" == "opencomposite.ini" ]]; then
      has_local_ini=1
    fi
    deploy_file "$f" "$install_dir" "$log"
  done

  if [[ "$has_local_ini" -eq 0 && -f "$GLOBAL_INI" ]]; then
    deploy_file "$GLOBAL_INI" "$install_dir" "$log"
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[oc-launch] (dry-run) would exec: %s\n' "$*"
    return 0
  fi

  if [[ $# -eq 0 ]]; then
    return 0
  fi

  exec "$@"
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 0
fi

case "$1" in
  -h | --help | help)
    print_help
    ;;
  list)
    shift
    cmd_list "$@"
    ;;
  status)
    shift
    cmd_status "$@"
    ;;
  restore)
    shift
    cmd_restore "$@"
    ;;
  --dry-run)
    shift
    DRY_RUN=1
    run_wrapper "$@"
    ;;
  *)
    run_wrapper "$@"
    ;;
esac
