{pkgs, ...}: let
  huggingfaceCache = "/hdd/huggingface";

  llama-cpp-pkg = pkgs.callPackage ../pkgs/llama-cpp/default.nix {
    inherit (pkgs) llama-cpp;
  };

  # Build / runtime cost notes (see pkgs/packaging.md):
  # - llama-cpp (nixpkgs-cuda): long first compile, cacheable; required for GPU llama-server
  # - llama-swap / ollama / opencode: prebuilt, fast
  # - wyoming.faster-whisper (CUDA, large-v3-turbo): heavy Python+CTranslate2; downloads GB of weights at runtime
  # - wyoming.piper (useCUDA): moderate; voice model download at runtime
  # - wyoming.openwakeword: light
in {
  imports = [
    ../pkgs/overrides.nix
  ];

  environment.systemPackages = with pkgs; [
    llama-cpp-pkg
    (callPackage ../pkgs/opencode/default.nix {})
    (callPackage ../pkgs/OpenAgentsControl/default.nix {})
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
    file.xdg_config."opencode/skills".source = "{{home}}/etc/nixos/dev/opencode/skills";
  };

  environment.sessionVariables = {
    HF_HUB_CACHE = huggingfaceCache;
  };

  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama; # prebuilt GitHub release (pkgs/ollama)
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   environmentVariables.OLLAMA_KEEP_ALIVE = "1h";
  # };

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
        "HF_HUB_CACHE=${huggingfaceCache}"
      ];
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  services.wyoming.faster-whisper = {
    servers.english = {
      enable = true;
      model = "large-v3-turbo";
      language = "auto";
      device = "cuda";
      uri = "tcp://0.0.0.0:10300";
    };
  };

  systemd.services.wyoming-faster-whisper-main = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      MemoryMax = "16G";
      MemoryHigh = "14G";
    };
  };

  services.wyoming.piper.servers.yoda = {
    enable = true;
    voice = "en-us-ryan-high";
    uri = "tcp://0.0.0.0:10200";
    useCUDA = true;
  };

  services.wyoming.openwakeword = {
    enable = true;
    uri = "tcp://0.0.0.0:10400";
  };

  networking.firewall.allowedTCPPorts = [
    10400
    10200
    10300
    10301
    # 11434 # Ollama
    9292
    61337
  ];
}
