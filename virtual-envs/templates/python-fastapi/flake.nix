{
  description = "Python / FastAPI development environment (with Docker Compose support)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Python
            python313
            uv          # Fast Python package manager (replaces pip/venv/poetry)

            # Docker tooling (daemon is managed by NixOS, only CLI needed here)
            docker-compose

            # Useful CLI tools
            httpie      # Friendly HTTP client to test API endpoints (hey http://localhost:8000)
            jq          # JSON pretty-print for API responses
          ];

          shellHook = ''
            echo " Python/FastAPI env"
            echo "  python  $(python --version)"
            echo "  uv      $(uv --version)"
            echo ""
            echo "  Docker Compose commands:"
            echo "    docker compose up          — start all services"
            echo "    docker compose up -d       — start in background"
            echo "    docker compose down        — stop all services"
            echo "    docker compose logs -f     — follow logs"
            echo "    docker compose build       — rebuild images"
            echo ""
            echo "  Local dev (without Docker):"
            echo "    uv sync                    — install dependencies"
            echo "    uv run uvicorn app.main:app --reload"
          '';
        };
      });
}
