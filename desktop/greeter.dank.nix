{
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Disable the stable dms-greeter module (present since nixos-26.05)
  disabledModules = ["services/display-managers/dms-greeter.nix"];

  imports = [
    # Import the dms-greeter module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/services/display-managers/dms-greeter.nix"
  ];

  services.displayManager.dms-greeter = {
    enable = true;
    # Greeter was split out of DankMaterialShell into dank-greeter (pkgs.dms-greeter).
    # Do not point this at inputs.dms (shell-only) — that package no longer ships bin/dms-greeter.
    package = pkgs.dms-greeter;

    compositor = {
      name = "niri";
      # Passed to niri via -C by the nixos module (replaces /etc/greetd/niri.kdl).
      customConfig = ''
        hotkey-overlay {
          skip-at-startup
        }

        environment {
          DMS_RUN_GREETER "1"
        }

        gestures {
          hot-corners {
            off
          }
        }

        layout {
          background-color "#000000"
        }
      '';
    };

    # Sync your user's DankMaterialShell theme with the greeter. You'll probably want this
    configHome = "/home/chaton";

    # Custom config files for non-standard config locations
    configFiles = [
      "/home/chaton/.config/DankMaterialShell/settings.json"
    ];

    # Save the logs to a file
    logs = {
      save = true;
      path = "/tmp/dms-greeter.log";
    };

    # Custom Quickshell Package
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
  };

  services.greetd = {
    enable = true;
  };

  # Minimal maid activation for greeter home; desktop user units are gated with
  # ConditionUser=!dms-greeter elsewhere (dms, sunshine, nirinit, goxlr, …).
  users.users.dms-greeter.maid = {};
}
