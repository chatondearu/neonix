{pkgs, ...}: let
  huggingfaceCache = "/hdd/huggingface";
  # Build / runtime cost notes (see pkgs/packaging.md):
  # - llama-cpp CUDA: see dev/ai-llama.nix (optional, slow compile)
  # - llama-swap / ollama / opencode: prebuilt, fast
  # - wyoming.faster-whisper (CUDA, large-v3-turbo): heavy service closure; model download at runtime
  # - wyoming.piper (useCUDA): moderate; voice model download at runtime
  # - wyoming.openwakeword: light
in {
  imports = [
    ../pkgs/overrides.nix
    ./ai-llama.nix
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ../pkgs/opencode/default.nix {})
    (callPackage ../pkgs/OpenAgentsControl/default.nix {})
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
    file.xdg_config."opencode/skills".source = "{{home}}/etc/nixos/dev/opencode/skills";
  };

  environment.sessionVariables = {
    HF_HOME = huggingfaceCache;
    HF_HUB_CACHE = "${huggingfaceCache}/hub";
  };

  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama;
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   environmentVariables.OLLAMA_KEEP_ALIVE = "1h";
  # };

  services.wyoming.faster-whisper = {
    servers.english = {
      enable = true;
      model = "large-v3-turbo";
      language = "auto";
      # Keep CPU backend until the packaged ctranslate2 build has CUDA enabled.
      device = "cpu";
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
    61337
  ];
}
