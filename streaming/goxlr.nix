{
  pkgs,
  lib,
  ...
}: {
  services.goxlr-utility = {
    enable = true;
    package = pkgs.unstable.goxlr-utility;
    autoStart.xdg = true;
  };

  # Wire Line4 (broadcast mix) to the PRO X headset once PipeWire nodes exist.
  # Static loopback node.target is unreliable with WirePlumber 1.6+ at boot.
  systemd.user.services.goxlr-headset-route = {
    description = "Route GoXLR Line4 broadcast mix to Logitech PRO X headset";
    wantedBy = ["default.target"];
    wants = ["pipewire.service" "wireplumber.service"];
    after = ["pipewire.service" "wireplumber.service" "graphical-session.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "goxlr-headset-route" ''
        set -euo pipefail
        PW="${pkgs.pipewire}/bin/pw-link"

        SRC="alsa_input.usb-TC-Helicon_GoXLR-00.HiFi__Line4__source"
        DST="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo"

        for _ in $(seq 1 60); do
          if "$PW" -o 2>/dev/null | grep -qF "$SRC:capture_FL" && \
             "$PW" -i 2>/dev/null | grep -qF "$DST:playback_FL"; then
            "$PW" "$SRC:capture_FL" "$DST:playback_FL"
            "$PW" "$SRC:capture_FR" "$DST:playback_FR"
            echo "goxlr-headset-route: linked Line4 to PRO X headset"
            exit 0
          fi
          sleep 1
        done

        echo "goxlr-headset-route: timeout waiting for GoXLR Line4 or PRO X headset nodes" >&2
        exit 1
      '';
    };
  };
}
