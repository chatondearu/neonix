{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    unstable.floorp-bin # Firefox fork with vertical tabs
    # vesktop: Discord client with Vencord, no forced updates, native Wayland
    unstable.vesktop

    telegram-desktop
    jellyfin-desktop
  ];
}
