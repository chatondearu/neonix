# neo-nix: thin host overlay on ai-dev-kit (ADR-005). Skills come from the
# flake input via nix/maid.nix (not nixosModules.default: that re-imports
# nix-maid). cdamux.projectsRoot is single-valued upstream; append extra
# [[projects.roots]] here.
# Login restore of dormant agents is host-only: PRD-195 lists auto-restore as a non-goal.
{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [inputs.ai-dev-kit.nixosModules.cdaAitools];

  cda.aitools = {
    enable = true;
    user = "chaton";
    repoPath = "${inputs.ai-dev-kit}";
    configRoot = "/home/chaton/.config/cda-aitools";
    installMethod = "nix";
    enablePackages = true;
    deploy.enable = true;
    cdamux = {
      projectsRoot = "/hdd/dev";
      # Explicit state root so panes inherit it (#391). Same path as the XDG fallback.
      home = "/home/chaton/.local/state/cdamux";
      # Alt-N → dedicated cdamux-nav (ADR-014 / kit #349); needs deploy.enable
      navBind.enable = true;
    };
    tmux = {
      clipboard = "wayland";
      persist.enable = true;
    };
    mosh.enable = true;
    cdamuxd.enable = true;
    graphify = {
      enable = true;
      installMethod = "nix";
    };
    # Official Coolify CLI on PATH (kit #344). URL + token live in
    # age.secrets.coolify-token (never in the Nix store).
    coolify.enable = true;
    moshiHook = {
      enable = false;
    };
    systemdUser.conditionUser = "!dms-greeter";
  };

  users.users.chaton.maid = lib.mkMerge [
    (import "${inputs.ai-dev-kit}/nix/maid.nix" {
      repoPath = "${inputs.ai-dev-kit}";
      skillDirs = [
        ".cursor/skills"
        ".claude/skills"
        ".config/opencode/skills"
      ];
    })
    {
      file.xdg_config."cdamux/config.toml".source = lib.mkForce (
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
    }
  ];

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
        "CDAMUX_HOME=/home/chaton/.local/state/cdamux"
      ];
    };
  };

  systemd.user.services.coolify-env-sync = {
    description = "Bootstrap Coolify CLI context from agenix secret";
    after = ["default.target"];
    wantedBy = ["default.target"];
    unitConfig.ConditionUser = "!dms-greeter";
    unitConfig.ConditionPathExists = config.age.secrets.coolify-token.path;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/coolify-env-sync";
      Environment = ["PATH=/run/current-system/sw/bin"];
      EnvironmentFile = ["-${config.age.secrets.coolify-token.path}"];
    };
  };
}
