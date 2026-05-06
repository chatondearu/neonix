{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    (wrapFirefox
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPolicies = {
          DisableTelemetry = true;
        };
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

  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "0";
}
