{ pkgs ? import <nixpkgs> { } }:

let
  ssl-gen = pkgs.writeShellScriptBin "ssl-gen" ''
    set -euo pipefail
    if [ $# -eq 0 ]; then
      echo "Usage: ssl-gen <domain> [extra-domain ...]"
      exit 1
    fi

    DOMAIN="$1"
    CERT_DIR="$(pwd)/certs"
    WORK_DIR="$(pwd)/.certbot/work"
    LOGS_DIR="$(pwd)/.certbot/logs"
    CONF_DIR="$(pwd)/.certbot/conf"

    mkdir -p "$CERT_DIR" "$WORK_DIR" "$LOGS_DIR" "$CONF_DIR"

    DOMAINS="-d $1"
    shift
    for d in "$@"; do DOMAINS="$DOMAINS -d $d"; done

    certbot certonly \
      --manual \
      --preferred-challenges dns \
      --config-dir  "$CONF_DIR" \
      --work-dir    "$WORK_DIR" \
      --logs-dir    "$LOGS_DIR" \
      $DOMAINS

    # Certbot strips "*." from directory names for wildcard certs
    LIVE_DOMAIN="${DOMAIN#\*.}"
    LIVE="$CONF_DIR/live/$LIVE_DOMAIN"
    cp -L "$LIVE/fullchain.pem" "$CERT_DIR/fullchain.pem"
    cp -L "$LIVE/privkey.pem"   "$CERT_DIR/privkey.pem"
    cp -L "$LIVE/cert.pem"      "$CERT_DIR/cert.pem"
    cp -L "$LIVE/chain.pem"     "$CERT_DIR/chain.pem"

    echo ""
    echo "✓ Certificates saved in $CERT_DIR"
  '';

  ssl-renew = pkgs.writeShellScriptBin "ssl-renew" ''
    set -euo pipefail
    CONF_DIR="$(pwd)/.certbot/conf"
    WORK_DIR="$(pwd)/.certbot/work"
    LOGS_DIR="$(pwd)/.certbot/logs"
    CERT_DIR="$(pwd)/certs"

    if [ ! -d "$CONF_DIR" ]; then
      echo "No local certbot config found. Run ssl-gen first."
      exit 1
    fi

    certbot renew \
      --config-dir  "$CONF_DIR" \
      --work-dir    "$WORK_DIR" \
      --logs-dir    "$LOGS_DIR"

    for LIVE in "$CONF_DIR"/live/*/; do
      DOMAIN=$(basename "$LIVE")
      [ "$DOMAIN" = "README" ] && continue
      cp -L "$LIVE/fullchain.pem" "$CERT_DIR/fullchain.pem"
      cp -L "$LIVE/privkey.pem"   "$CERT_DIR/privkey.pem"
      cp -L "$LIVE/cert.pem"      "$CERT_DIR/cert.pem"
      cp -L "$LIVE/chain.pem"     "$CERT_DIR/chain.pem"
      echo "✓ $DOMAIN renewed → $CERT_DIR"
    done
  '';

  ssl-info = pkgs.writeShellScriptBin "ssl-info" ''
    set -euo pipefail
    CONF_DIR="$(pwd)/.certbot/conf"
    if [ ! -d "$CONF_DIR" ]; then
      echo "No local certbot config found."
      exit 1
    fi
    certbot certificates --config-dir "$CONF_DIR"
  '';

in pkgs.mkShell {
  packages = [ pkgs.certbot ssl-gen ssl-renew ssl-info ];

  shellHook = ''
    echo " Certbot env — $(certbot --version 2>&1)"
    echo ""
    echo "  ssl-gen <domain> [extra...]  — generate certificate (DNS challenge)"
    echo "  ssl-renew                    — renew all local certificates"
    echo "  ssl-info                     — show expiry dates"
    echo ""
    echo "  Certificates are saved in ./certs/"
  '';
}
