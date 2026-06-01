# Optional llama.cpp + llama-swap stack (CUDA build is slow).
# Enabled by default; disable in configuration if you want a smaller closure.
{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.neo.ai.llama;
  huggingfaceCache = "/hdd/huggingface";
in {
  options.neo.ai.llama = {
    enable =
      lib.mkEnableOption "llama.cpp CUDA stack (llama-swap + llama-server)"
      // {
        default = true;
        description = ''
          When disabled, llama-swap and llama-cpp are omitted from the system closure.
        '';
      };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        Pin a fixed llama-cpp package (e.g. output of `nix build .#llama-cpp-cuda`).
        Prevents rebuilds when nixpkgs changes but the pinned store path is unchanged.
      '';
    };

    toolsInPath = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Put llama-cli tools on PATH. Not required for llama-swap (uses llama-server only).
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    llama-cpp-pkg =
      if cfg.package != null
      then cfg.package
      else self.packages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-cuda;
  in {
    environment.systemPackages = lib.optionals cfg.toolsInPath [llama-cpp-pkg];

    environment.etc."llama-swap/config.yaml".source = pkgs.replaceVars ./llama-swap/config.yaml.template {
      llamaServerPath = "${llama-cpp-pkg}/bin/llama-server";
    };

    systemd.services.llama-swap = {
      description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = "chaton";
        Group = "users";
        ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
        Restart = "always";
        RestartSec = 10;
        Environment = [
          "PATH=/run/current-system/sw/bin"
          "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
          "HF_HOME=${huggingfaceCache}"
          "HF_HUB_CACHE=${huggingfaceCache}/hub"
        ];
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    networking.firewall.allowedTCPPorts = [
      9292
    ];
  });
}
