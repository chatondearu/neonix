# neo-nix: thin host overlay on ai-dev-kit cda.aitools (ADR-003).
# cdamux.projectsRoot is single-valued upstream; append extra [[projects.roots]] here.
# Login restore of dormant agents is host-only: PRD-195 lists auto-restore as a non-goal.
{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [inputs.ai-dev-kit.nixosModules.cdaAitools];

  cda.aitools = {
    enable = true;
    user = "chaton";
    repoPath = "{{home}}/dev/chatondearu/ai-dev-kit";
    configRoot = "/home/chaton/.config/cda-aitools";
    installMethod = "auto";
    enablePackages = true;
    deploy.enable = true;
    cdamux.projectsRoot = "/hdd/dev";
    tmux = {
      clipboard = "wayland";
      persist.enable = true;
    };
    mosh.enable = true;
    cdamuxd.enable = true;
    graphify = {
      enable = true;
      installMethod = "auto"; # pinned Nix wheel, else uv at activation
    };
    moshiHook = {
      enable = true;
      hookTargets = ["cursor"];
    };
    systemdUser.conditionUser = "!dms-greeter";
  };

  users.users.chaton.maid.file.xdg_config."cdamux/config.toml".source = lib.mkForce (
    pkgs.writeText "cdamux-config.toml" (
      builtins.replaceStrings ["@PROJECTS_ROOT@"] ["/hdd/dev"] (
        builtins.readFile "${inputs.ai-dev-kit}/aitools/templates/cdamux/config.toml"
      )
      + ''

        [[projects.roots]]
        path = "/home/chaton/etc/nixos"
        label = "nixos"
      ''
    )
  );

  # After login: recreate dormant registry sessions on their agent conversation.
  systemd.user.services.cdamux-restore-dormant = {
    description = "Restore dormant cdamux agent sessions (registry ADR-009)";
    after = ["default.target"];
    wantedBy = ["default.target"];
    unitConfig.ConditionUser = "!dms-greeter";
    serviceConfig = {
      Type = "oneshot";
      # System binary — avoid ~/.nix-profile shadowing an old cdamux.
      ExecStart = "/run/current-system/sw/bin/cdamux restore --all";
      Environment = [
        "PATH=/run/current-system/sw/bin:%h/.local/bin"
      ];
    };
  };
}
