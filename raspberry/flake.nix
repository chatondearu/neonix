{
  description = "Raspberry Pi Imager + odio HW validation (Pi Zero W / Merus AMP)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        odioDir = ./odio;
        manifestUrl = "https://beta.odio.love/odio.rpi-imager-manifest";

        rpi-imager-odio = pkgs.writeShellScriptBin "rpi-imager-odio" ''
          set -euo pipefail
          cat <<EOF
          odio flash (Pi Zero W / WH, armhf)
          ────────────────────────────────────
          1. Imager → Options → Content Repository → Use custom URL
          2. URL: ${manifestUrl}
          3. Select odio (armhf) — not arm64 on Zero W
          4. Settings: user "odio", enable SSH, Wi-Fi if needed
          5. Flash SD, then: apply-merus-config /dev/sdX
          Or use: flash-odio-cli /dev/sdX
          EOF
          exec ${pkgs.rpi-imager}/bin/rpi-imager "$@"
        '';

        apply-merus-config = pkgs.writeShellScriptBin "apply-merus-config" ''
          exec ${odioDir}/apply-merus-config.sh "$@"
        '';

        flash-odio-cli = pkgs.writeShellScriptBin "flash-odio-cli" ''
          exec ${odioDir}/flash-odio-cli.sh "$@"
        '';

        deploy-usb-route = pkgs.writeShellScriptBin "deploy-usb-route" ''
          exec ${odioDir}/deploy-usb-route.sh "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rpi-imager
            rpi-imager-odio
            flash-odio-cli
            apply-merus-config
            deploy-usb-route
            jq
            curl
            util-linux
            dosfstools
            parted
            zstd
            openssh
          ];

          shellHook = ''
            export RASPBERRY_ODIO_DIR="$PWD/odio"
            echo " raspberry/ — odio HW validation (Pi Zero W/WH + Merus AMP)"
            echo ""
            echo "  flash-odio-cli /dev/sdX     odio armhf + Merus (Pi Zero W/WH)"
            echo "  flash-odio-cli /dev/sdX --arm64   Pi Zero 2 W / Pi 3+ only"
            echo "  apply-merus-config /dev/sdX  Merus overlay only"
            echo "  deploy-usb-route odio@host --status   phase 2 USB → Merus"
            echo "  rpi-imager-odio              GUI Imager"
            echo ""
            echo "  Manifest: ${manifestUrl}"
            echo "  Docs: odio/README.md"
          '';
        };
      }
    );
}
