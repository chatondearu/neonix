{
  description = "Raspberry Pi Imager + odio HW validation (Pi Zero 2 W / Merus AMP)";

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
          odio flash (Pi Zero 2 W, arm64)
          ─────────────────────────────────
          1. Imager → Options → Content Repository → Use custom URL
          2. URL: ${manifestUrl}
          3. Select odio (arm64)
          4. Settings: user "odio", enable SSH, Wi-Fi if needed
          5. Flash SD, then: apply-merus-config /dev/sdX
          EOF
          exec ${pkgs.rpi-imager}/bin/rpi-imager "$@"
        '';

        apply-merus-config = pkgs.writeShellScriptBin "apply-merus-config" ''
          exec ${odioDir}/apply-merus-config.sh "$@"
        '';

        flash-odio-cli = pkgs.writeShellScriptBin "flash-odio-cli" ''
          exec ${odioDir}/flash-odio-cli.sh "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rpi-imager
            rpi-imager-odio
            flash-odio-cli
            apply-merus-config
            jq
            curl
            util-linux
            dosfstools
            parted
            zstd
          ];

          shellHook = ''
            export RASPBERRY_ODIO_DIR="$PWD/odio"
            echo " raspberry/ — odio HW validation (Pi Zero 2 W + Merus AMP)"
            echo ""
            echo "  flash-odio-cli /dev/sdX     Recommended: CLI flash + Merus (uses odio/.env)"
            echo "  apply-merus-config /dev/sdX  Merus overlay only (after manual flash)"
            echo "  rpi-imager-odio              GUI Imager (needs Polkit / display)"
            echo ""
            echo "  Manifest: ${manifestUrl}"
            echo "  Docs: odio/README.md"
          '';
        };
      }
    );
}
