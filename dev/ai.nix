{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  huggingfaceCache = "/hdd/huggingface";
  # Build / runtime cost notes (see pkgs/packaging.md):
  # - llama-cpp CUDA: see dev/ai-llama.nix (optional, slow compile)
  # - llama-swap / ollama / opencode: prebuilt, fast
  # - wyoming.faster-whisper (large-v3-turbo): heavy service closure; prefers CUDA when ctranslate2 supports it; model download at runtime
  # - wyoming.piper (useCUDA): moderate; voice model download at runtime
  # - wyoming.openwakeword: light
in {
  imports = [
    ../pkgs/overrides.nix
    ./ai-llama.nix
    ./ai-stt.nix
    inputs.neomind.nixosModules.neomind
  ];

  environment.systemPackages = with pkgs; [
    (callPackage ../pkgs/opencode/default.nix {})
    (callPackage ../pkgs/OpenAgentsControl/default.nix {})
    (callPackage ../pkgs/dictation-ptt/default.nix {})
  ];

  # Official live daemon: systemd neomind (User=chaton). After switch, stop
  # ~/.local/share/neomind/run-live.sh so only one daemon remains.
  # identity paths omitted → $HOME/.local/share/neomind/{memory,agent.key,ask.sock}
  # installKind defaults to nix_desktop (module).
  services.neomind = {
    enable = true;
    user = "chaton";
    agent = "neo-nix";
    model = "glm-4.7-flash:q4";
    modelUrl = "http://127.0.0.1:9292/v1";
    # agenix file is LLAMA_SWAP_API_KEY=; remap below. No second secret.
    environmentFile = config.age.secrets.llama-swap-api-key.path;
  };

  # Same mapping as run-live.sh: EnvironmentFile loads LLAMA_SWAP_API_KEY.
  # Default systemd PATH is too small for host cdamux (neomind status → cdamux on).
  systemd.services.neomind.path = [config.system.path];
  systemd.services.neomind.serviceConfig.ExecStart = lib.mkForce "${pkgs.writeShellScript "neomind-run" ''
    export NEOMIND_MODEL_KEY="''${LLAMA_SWAP_API_KEY:?}"
    exec ${config.services.neomind.package}/bin/neomind run
  ''}";

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
      language = "fr";
      # ctranslate2 in nixpkgs is not built with CUDA; keep CPU until an overlay enables it.
      device = "cpu";
      sttLibrary = "faster-whisper";
      uri = "tcp://127.0.0.1:10300";
      initialPrompt = "Dictée technique en français. Termes possibles : API, commit, pull request, TypeScript, NixOS, flake, props, endpoint.";
    };
  };

  systemd.services.wyoming-faster-whisper-english = {
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
    uri = "tcp://127.0.0.1:10200";
    useCUDA = true;
  };

  services.wyoming.openwakeword = {
    enable = true;
    uri = "tcp://127.0.0.1:10400";
  };

  networking.firewall.allowedTCPPorts = [
    # 11434 # Ollama
    61337
  ];
}
