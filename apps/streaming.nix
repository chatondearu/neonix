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
    self.packages.${pkgs.system}.goxlr-router
  ];

  services.goxlr-utility = {
    enable = true;
    package = pkgs.unstable.goxlr-utility;
    autoStart.xdg = true;
  };

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

  # Route GoXLR Headphones split (AUX4/AUX5) to Logitech PRO X Wireless
  systemd.user.services."goxlr-audio-route" = {
    description = "Route GoXLR Headphones (AUX4/AUX5) to Logitech PRO X Wireless";
    wantedBy = ["default.target"];
    wants = ["pipewire.service" "wireplumber.service"];
    after = ["pipewire.service" "wireplumber.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "goxlr-audio-route.sh" ''
        PW="${pkgs.pipewire}/bin/pw-link"

        SRC_L="alsa_output.hw_GoXLR_0:monitor_AUX4"
        SRC_R="alsa_output.hw_GoXLR_0:monitor_AUX5"
        DST_L="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo:playback_FL"
        DST_R="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo:playback_FR"

        for i in $(seq 1 60); do
          if "$PW" -o 2>/dev/null | grep -qF "$SRC_L" && \
             "$PW" -i 2>/dev/null | grep -qF "$DST_L"; then
            "$PW" "$SRC_L" "$DST_L" 2>/dev/null || true
            "$PW" "$SRC_R" "$DST_R" 2>/dev/null || true
            echo "goxlr-audio-route: links created"
            exit 0
          fi
          sleep 1
        done

        echo "goxlr-audio-route: timeout waiting for ports" >&2
        exit 1
      '';
    };
  };
}
