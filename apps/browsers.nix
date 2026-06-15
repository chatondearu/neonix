{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    (
      wrapFirefox
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPolicies = {
          DisableTelemetry = true;
        };
        # Required for screencast on niri (Google Meet, etc.)
        # https://github.com/niri-wm/niri/wiki/Application-Issues#zen-browser
        extraPrefs = ''
          defaultPref("widget.dmabuf.force-enabled", true);
        '';
      }
    )

    #inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default # Zen Browser - https://wiki.nixos.org/wiki/Zen_Browser

    # vesktop: Discord client with Vencord, no forced updates, native Wayland
    # WARNING: actually we need to disable the discord option `2026-03-linux-vulkan-capture` to avoid screen sharing issues
    # see : https://github.com/niri-wm/niri/discussions/3921
    unstable.vesktop

    telegram-desktop
    jellyfin-desktop
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;

    policies = {
      DisableTelemetry = true;
    };
  };

  # Nixpkgs vesktop runs via the electron wrapper; block its auto mic gain adjustments.
  # Verify with: pactl list source-outputs (during a call) → application.process.*
  services.pipewire.extraConfig.pipewire-pulse."10-vesktop-block-source-volume" = {
    "pulse.rules" = [
      {
        matches = [
          {"application.process.binary" = "vesktop";}
          {
            "application.process.binary" = "electron";
            "application.process.command" = "~.*Vesktop.*";
          }
        ];
        actions = {
          quirks = ["block-source-volume"];
        };
      }
    ];
  };
}
