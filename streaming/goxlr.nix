{
  pkgs,
  self,
  ...
}: {
  # environment.systemPackages = with pkgs; [
  #   self.packages.${pkgs.system}.goxlr-router
  # ];

  services.goxlr-utility = {
    enable = true;
    package = pkgs.unstable.goxlr-utility;
    autoStart.xdg = true;
  };

  # # Reroute GoXLR Headphones sink split from GoXLR hardware to Logitech PRO X.
  # # Disconnect split -> GoXLR hw, then connect split -> Logitech.
  # # Apps targeting the GoXLR "Headphones" sink will be heard on the Logitech.
  # systemd.user.services."goxlr-audio-route" = {
  #   description = "Route GoXLR Headphones sink to Logitech PRO X Wireless";
  #   wantedBy = ["default.target"];
  #   wants = ["pipewire.service" "wireplumber.service"];
  #   after = ["pipewire.service" "wireplumber.service"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = pkgs.writeShellScript "goxlr-audio-route.sh" ''
  #       PW="${pkgs.pipewire}/bin/pw-link"

  #       SPLIT_L="alsa_output.usb-TC-Helicon_GoXLR-00.HiFi__Headphones__sink.split:output_AUX4"
  #       SPLIT_R="alsa_output.usb-TC-Helicon_GoXLR-00.HiFi__Headphones__sink.split:output_AUX5"
  #       GOXLR_L="alsa_output.hw_GoXLR_0:playback_AUX4"
  #       GOXLR_R="alsa_output.hw_GoXLR_0:playback_AUX5"
  #       LOGI_L="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo:playback_FL"
  #       LOGI_R="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo:playback_FR"

  #       for i in $(seq 1 60); do
  #         if "$PW" -o 2>/dev/null | grep -qF "$SPLIT_L" && \
  #            "$PW" -i 2>/dev/null | grep -qF "$LOGI_L"; then

  #           # Disconnect split from GoXLR hardware headphone jack
  #           "$PW" -d "$SPLIT_L" "$GOXLR_L" 2>/dev/null || true
  #           "$PW" -d "$SPLIT_R" "$GOXLR_R" 2>/dev/null || true

  #           # Connect split to Logitech headset
  #           "$PW" "$SPLIT_L" "$LOGI_L" 2>/dev/null || true
  #           "$PW" "$SPLIT_R" "$LOGI_R" 2>/dev/null || true

  #           echo "goxlr-audio-route: headphones sink redirected to Logitech"
  #           exit 0
  #         fi
  #         sleep 1
  #       done

  #       echo "goxlr-audio-route: timeout waiting for ports" >&2
  #       exit 1
  #     '';
  #   };
  # };

  # wpctl status
  # pw-loopback --capture-props='node.target="alsa_output.usb-TC-Helicon_GoXLR-00.HiFi__Headphones__sink.monitor"' --playback-props='node.target="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo"'

  services.pipewire.extraConfig.pipewire."99-goxlr-to-pro-x" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Sortie Casque GoXLR vers PRO X USB";
          "capture.props" = {
            "node.target" = "alsa_output.usb-TC-Helicon_GoXLR-00.HiFi__Headphones__sink.monitor";
            "node.passive" = true;
          };
          "playback.props" = {
            "node.target" = "alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo";
          };
        };
      }
    ];
  };
}
