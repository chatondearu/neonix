{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # OpenCode - https://opencode.ai/
    unstable.opencode-desktop
    (callPackage ../pkgs/opencode/default.nix { })

    # LM Studio - https://lmstudio.ai/
    unstable.lmstudio

    # Openwork - https://github.com/different-ai/openwork
    # (callPackage ../pkgs/openwork/default.nix { })

    (callPackage ../pkgs/OpenAgentsControl/default.nix { })
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
    file.xdg_config."opencode/skills".source = "{{home}}/etc/nixos/dev/opencode/skills";
  };

  environment.sessionVariables = {
    # for opencode
    #OLLAMA_CONTEXT_LENGTH=64000;
  };

  # LM Studio audio requires rtkit (enabled in system/security.nix)
}
