{
  pkgs,
  self,
  ...
}: {
  ## TO INSTALL :
  # - Stream Deck hardware support
  # - Twitchat
  # - obs-vertical-canvas

  ## TO TEST :
  # - Speaker.bot
  # - MacroGraph

  environment.systemPackages = with pkgs; [
    # Stream Deck hardware support
    unstable.streamcontroller
  ];

  # OBS Studio with NVIDIA CUDA and virtual camera
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override {cudaSupport = true;};
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-move-transition
    ];
  };

  imports = [
    ./goxlr.nix
  ];
}
