{ lib, pkgs, inputs, ... }:

{
  imports = [
    # Import the dms-greeter module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/services/display-managers/dms-greeter.nix"
  ];

  services.displayManager.dms-greeter = {
    enable = true;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;

    compositor = {
      name = "niri";
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

  environment.etc."greetd/niri.kdl".text = ''
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

  services.greetd = {
    enable = true;
  };

  users.users.dms-greeter.maid = {};
}