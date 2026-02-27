{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # OpenCode - https://opencode.ai/
    unstable.opencode
    unstable.opencode-desktop

    # LM Studio - https://lmstudio.ai/
    unstable.lmstudio
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
  };

  environment.sessionVariables = {
    # for opencode
    #OLLAMA_CONTEXT_LENGTH=64000;
  };

  # LM Studio audio requires rtkit (enabled in system/security.nix)
}
