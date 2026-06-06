# Resolve odio/.env in the git checkout (not the Nix store copy of scripts).
resolve_odio_config_dir() {
  if [ -n "${RASPBERRY_ODIO_DIR:-}" ] && [ -f "${RASPBERRY_ODIO_DIR}/.env" ]; then
    printf '%s' "$RASPBERRY_ODIO_DIR"
    return 0
  fi
  if [ -f "${PWD}/odio/.env" ]; then
    printf '%s' "${PWD}/odio"
    return 0
  fi
  if [ -f "${PWD}/.env" ] && [ -f "${PWD}/config.txt" ]; then
    printf '%s' "${PWD}"
    return 0
  fi
  return 1
}
