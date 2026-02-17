{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.streamcontroller
  ];

  programs.streamdeck-ui = {
    enable = true;
    autoStart = true;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-move-transition
    ];
  };

  programs.obs-studio.package = pkgs.obs-studio.override { cudaSupport = true; };
}
