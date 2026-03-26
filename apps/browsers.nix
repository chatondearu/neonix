{ pkgs, inputs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default # Zen Browser - https://wiki.nixos.org/wiki/Zen_Browser

    # vesktop: Discord client with Vencord, no forced updates, native Wayland
    unstable.vesktop

    telegram-desktop
    jellyfin-desktop
  ];
}
