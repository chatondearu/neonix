{ pkgs, ... }:

{
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
  };

  # AI & Machine Learning services
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "1h";
    };
  };

  environment.etc."llama-swap/config.yaml".text = ''
        
    # llama-swap configuration
    # This config uses llama.cpp's server to serve models on demand

    models:  # Ordered from newest to oldest

      # Uploaded 2026-04-02, size 18.8 GB, max ctx: 262144, layers: 60
      # Source: https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/blob/main/gemma-4-31B-it-UD-Q4_K_XL.gguf
      "gemma-4:31b-q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          # -hf unsloth/gemma-4-31B-it-GGUF:UD-Q4_K_XL
          --model unsloth/gemma-4-31B-it-GGUF/gemma-4-31B-it-UD-Q4_K_XL.gguf
          --mmproj unsloth/gemma-4-31B-it-GGUF/mmproj-BF16.gguf
          --alias "unsloth/gemma-4-31B-it-GGUF"
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

      # Same Gemma 4 weights, but disables <|think|> injection in the chat template
      "gemma-4:31b-q4-nothink":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          --model unsloth/gemma-4-31B-it-GGUF/gemma-4-31B-it-UD-Q4_K_XL.gguf
          --mmproj unsloth/gemma-4-31B-it-GGUF/mmproj-BF16.gguf
          --alias "unsloth/gemma-4-31B-it-GGUF"
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --chat-template-kwargs '{"enable_thinking": false}'
          --jinja

      # Qwen3.5-35B-A3B - MoE model with 35B total / 3B active params
      "qwen3.5:35b-a3b-q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Qwen3.5-35B-A3B-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 512
          --threads 1
          --jinja

      # GLM-4.7-Flash - Fixed with scoring_func sigmoid metadata
      # General use: --temp 1.0 --top-p 0.95, Tool-calling: --temp 0.7 --top-p 1.0
      "glm-4.7-flash:q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          --model unsloth/GLM-4.7-Flash-GGUF/GLM-4.7-Flash-UD-Q4_K_XL.gguf
          --alias "unsloth/GLM-4.7-Flash"
          --port ''${PORT}
          --ctx-size 200000
          --batch-size 2048
          --ubatch-size 512
          --temp 1.0
          --top-p 0.95
          --min-p 0.01
          --threads 1
          --jinja

      # Uploaded 2025-12-10, size 13.5 GB, max ctx: 393216, layers: 40
      "devstral-2:24b-q4":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q4_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --jinja

      # Uploaded 2025-12-10, size 27.0 GB, max ctx: 393216, layers: 40
      "devstral-2:24b-q8":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF:UD-Q8_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --jinja

      # Uploaded 2025-10-02, size 16.8 GB, max ctx: 262400, layers: 48
      "apriel-thinker:15b":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf unsloth/Apriel-1.5-15b-Thinker-GGUF:UD-Q8_K_XL
          --port ''${PORT}
          --ctx-size 65536
          --batch-size 2048
          --ubatch-size 2048
          --threads 1
          # --chat-template-file /etc/llama-templates/apriel-thinker.jinja

      # Uploaded 2025-09-04, size 0.3 GB, max ctx: 2048, layers: 24
      "embeddinggemma:300m":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf ggml-org/embeddinggemma-300M-GGUF
          --port ''${PORT}
          --embeddings
          --batch-size 2048
          --ubatch-size 2048

      # Uploaded 2025-08-02, size 11.3 GB, max ctx: 131072, layers: 24
      "gpt-oss-low:20b":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf ggml-org/gpt-oss-20b-GGUF
          --port ''${PORT}
          --ctx-size 0
          --batch-size 4096
          --ubatch-size 2048
          --threads 1
          --chat-template-kwargs '{"reasoning_effort": "low"}'
          --jinja

      # Uploaded 2025-08-02, size 11.3 GB, max ctx: 131072, layers: 24
      "gpt-oss-medium:20b":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf ggml-org/gpt-oss-20b-GGUF
          --port ''${PORT}
          --ctx-size 0
          --batch-size 4096
          --ubatch-size 2048
          --threads 1
          --chat-template-kwargs '{"reasoning_effort": "medium"}'
          --jinja

      # Uploaded 2025-08-02, size 11.3 GB, max ctx: 131072, layers: 24
      "gpt-oss-high:20b":
        cmd: |
          ${pkgs.llama-cpp}/bin/llama-server
          -hf ggml-org/gpt-oss-20b-GGUF
          --port ''${PORT}
          --ctx-size 0
          --batch-size 4096
          --ubatch-size 2048
          --threads 1
          --chat-template-kwargs '{"reasoning_effort": "high"}'
          --jinja

    healthCheckTimeout: 28800  # 8 hours for large model download + loading

    # TTL keeps models in memory for specified seconds after last use
    ttl: 3600  # Keep models loaded for 1 hour (like OLLAMA_KEEP_ALIVE)

    # Groups allow running multiple models simultaneously
    groups:
      embedding:
        # Keep embedding model always loaded alongside any other model
        persistent: true  # Prevents other groups from unloading this
        swap: false       # Don't swap models within this group
        exclusive: false  # Don't unload other groups when loading this
        members:
          - "embeddinggemma:300m"
  '';

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
      11434 # Ollama
      9292 # Llama-swap
      61337 # Agent-cli
    ];
  };
}
