{ pkgs, ... }:

{
  imports = [
    ../pkgs/overrides.nix
  ];

  environment.systemPackages = with pkgs; [
    # OpenCode - https://opencode.ai/
    # unstable.opencode-desktop
    (callPackage ../pkgs/opencode/default.nix { })

    # Openwork - https://github.com/different-ai/openwork
    # (callPackage ../pkgs/openwork/default.nix { })

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

  environment.etc."llama-swap/config.yaml".source = ./llama-swap/config.yaml;

  services.wyoming.faster-whisper = {
    servers.english = {
      enable = false;
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
}
