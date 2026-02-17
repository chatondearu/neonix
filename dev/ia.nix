{ pkgs, ... }:

{
  environment.systemPackages = with pkgs;[
    #claude-code # CLI for Claude Code TOTEST

    # OpenClaw
    #openclaw # Only available for MacOS or linux Headless. use Home manager to install all things in one.

    # OpenCode - https://opencode.ai/
    unstable.opencode
    unstable.opencode-desktop

    # LM Studio - https://lmstudio.ai/
    unstable.lmstudio
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode.json";
  };

  # services.ollama = {
  #   enable = true;

  #   # Use the CUDA package for better performance on NVIDIA GPUs
  #   # will add nvidia-smi
  #   package = pkgs.ollama-cuda;

  #   # Optional: preload models, see https://ollama.com/library
  #   #loadModels = [ "llama3.2:3b" "deepseek-r1:1.5b"];
  # };

  environment.sessionVariables = {
    # for claude-code
    #ANTHROPIC_AUTH_TOKEN = "ollama";
    #ANTHROPIC_BASE_URL = "http://localhost:11434";

    # for opencode
    #OLLAMA_CONTEXT_LENGTH=64000; # set a bigger context length for opencode
    #OPENCODE_CONFIG = "/etc/opencode/config.json";
  };

  # Required for LM Studio to work with audio
  security.rtkit.enable = true;
}