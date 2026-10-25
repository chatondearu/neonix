# neo-nix: thin host overlay on ai-dev-kit cda.aitools (ADR-003).
{inputs, ...}: {
  imports = [inputs.ai-dev-kit.nixosModules.cdaAitools];

  cda.aitools = {
    enable = true;
    user = "chaton";
    repoPath = "{{home}}/dev/chatondearu/ai-dev-kit";
    configRoot = "/home/chaton/.config/cda-aitools";
    installMethod = "auto";
    enablePackages = true;
    deploy.enable = true;
    ccmux.projectsRoot = "/hdd/dev";
    tmux = {
      clipboard = "wayland";
      persist.enable = true;
    };
    mosh.enable = true;
    ccmuxd.enable = true;
    moshiHook = {
      enable = true;
      hookTargets = ["cursor"];
    };
    systemdUser.conditionUser = "!dms-greeter";
  };
}
