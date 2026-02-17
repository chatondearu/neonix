{ pkgs, ... }:

{
  # Stream Deck hardware support
  programs.streamdeck-ui = {
    enable = true;
    autoStart = true;
  };

  # OBS Studio with NVIDIA CUDA and virtual camera
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override { cudaSupport = true; };
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-move-transition
    ];
  };
}
