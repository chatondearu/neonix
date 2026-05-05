{ pkgs, ... }:

let
  huggingfaceCache = "/hdd/huggingface";
in {
  imports = [
    ../pkgs/overrides.nix
  ];

  environment.systemPackages = with pkgs; [
    unstable.llama-cpp

    # OpenCode - https://opencode.ai/
    # unstable.opencode-desktop
    (callPackage ../pkgs/opencode/default.nix { })

    (callPackage ../pkgs/OpenAgentsControl/default.nix { })

    #agent-cli # special commands for ai powered dev https://github.com/basnijholt/agent-cli
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
    file.xdg_config."opencode/skills".source = "{{home}}/etc/nixos/dev/opencode/skills";
  };

  environment.sessionVariables = {
    # for opencode
    #OLLAMA_CONTEXT_LENGTH=64000;
    # for llama-swap
    HF_HUB_CACHE=huggingfaceCache; # cache for huggingface models
  };

  # AI & Machine Learning services
  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-cuda;
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   environmentVariables = {
  #     OLLAMA_KEEP_ALIVE = "1h";
  #   };
  # };

  environment.etc."llama-swap/config.yaml".source = pkgs.replaceVars ./llama-swap/config.yaml.template {
    llamaServerPath = "${pkgs.llama-cpp}/bin/llama-server";
  };

  systemd.services.llama-swap = {
    description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "chaton";
      Group = "users";
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
      Restart = "always";
      RestartSec = 10;
      # Environment for CUDA support
      Environment = [
        "PATH=/run/current-system/sw/bin"
        "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
        "HF_HUB_CACHE=${huggingfaceCache}"
      ];
      # Environment needs access to cache directories for model downloads
      # Simplified security settings to avoid namespace issues
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  services.wyoming.faster-whisper = {
    servers.english = {
      enable = true;
      model = "large-v3-turbo";
      language = "auto";
      device = "cuda"; # or "cpu" if no GPU
      uri = "tcp://0.0.0.0:10300";
    };
  };

  # --- Wyoming Faster Whisper Hardening ---
  # Auto-restart on failure (including OOM kills)
  systemd.services.wyoming-faster-whisper-main = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
      # Memory limits to prevent system-wide OOM
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

  # Firewall rules for Wyoming services and Llama
  networking.firewall = {
    allowedTCPPorts = [
      10400 # Wyoming OpenWakeboard
      10200 # Wyoming Piper
      10300 # Wyoming Whisper
      10301
      # 11434 # Ollama
      9292 # Llama-swap
      61337 # Agent-cli
    ];
  };
}
