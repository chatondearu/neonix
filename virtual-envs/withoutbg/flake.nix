{
  description = "withoutbg — AI background removal, runs via Docker (no install needed)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Main script: pull image if needed and start the container.
        # Images are cached by Docker, so subsequent runs are instant.
        # Output folder is the current directory when nix run is called.
        withoutbg-start = pkgs.writeShellScriptBin "withoutbg-start" ''
          set -euo pipefail

          PORT="''${WITHOUTBG_PORT:-8088}"
          OUTPUT_DIR="$(pwd)/output"
          mkdir -p "$OUTPUT_DIR"

          echo " withoutbg — AI Background Removal"
          echo "  Pulling image (skipped if already cached)..."
          docker pull withoutbg/app:latest

          echo ""
          echo "  Starting on http://localhost:$PORT"
          echo "  Output saved to: $OUTPUT_DIR"
          echo "  Press Ctrl+C to stop"
          echo ""

          docker run --rm \
            -p "$PORT:80" \
            -v "$OUTPUT_DIR:/app/output" \
            withoutbg/app:latest
        '';

      in {
        # nix run .  →  starts withoutbg directly
        apps.default = {
          type = "app";
          program = "${withoutbg-start}/bin/withoutbg-start";
        };

        # nix develop .  →  shell with the command available
        devShells.default = pkgs.mkShell {
          packages = [ withoutbg-start pkgs.docker ];

          shellHook = ''
            echo " withoutbg env ready"
            echo "  withoutbg-start        — start on http://localhost:8088"
            echo "  WITHOUTBG_PORT=9000 withoutbg-start  — custom port"
          '';
        };
      });
}
