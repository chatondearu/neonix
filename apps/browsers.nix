{ pkgs, ... }:

{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    unstable.floorp-bin # Firefox fork with vertical tabs
    unstable.discord
  ];
}
