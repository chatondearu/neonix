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

  # PipeWire: route GoXLR Headphones *split* (hardware mix to the physical jack) to Logitech PRO X Wireless.
  # Sources are output_AUX4 / output_AUX5 on the split node (not monitor_FL/FR, which may only reflect chat).
  # One link per output port: disconnect split -> hw_GoXLR before linking split -> headset.
  systemd.user.services."goxlr-audio-route" = {
    description = "Route GoXLR Headphones split (AUX4/AUX5) to Logitech PRO X Wireless (PipeWire)";
    wantedBy = ["default.target"];
    wants = ["pipewire.service" "wireplumber.service"];
    after = [
      "pipewire.service"
      "wireplumber.service"
      "graphical-session.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "goxlr-audio-route.sh" ''
        set -uo pipefail
        PW_LINK="${pkgs.pipewire}/bin/pw-link"
        PW_DUMP="${pkgs.pipewire}/bin/pw-dump"

        goxlr_headphones_split() {
          local n
          if [[ -x "$PW_DUMP" ]]; then
            n=$("$PW_DUMP" 2>/dev/null | grep -F '"node.name"' | grep -F 'HiFi__Headphones__sink.split' | head -1 | sed 's/.*"node.name": "\([^"]*\)".*/\1/')
            [[ -n "$n" ]] && echo "$n" && return 0
          fi
          echo "alsa_output.usb-TC-Helicon_GoXLR-00.HiFi__Headphones__sink.split"
        }

        logitech_sink_base() {
          if [[ -x "$PW_DUMP" ]]; then
            "$PW_DUMP" 2>/dev/null | grep -F '"node.name"' | grep -F 'alsa_output.usb-Logitech_PRO_X' | grep -F 'analog-stereo' | grep -F 'Wireless_Gaming_Headset' | head -1 | sed 's/.*"node.name": "\([^"]*\)".*/\1/'
          fi
        }

        resolve_ports() {
          local split logi
          split=$(goxlr_headphones_split)
          logi=$(logitech_sink_base)
          if [[ -z "$logi" ]]; then
            logi=$("$PW_LINK" -l 2>/dev/null | grep -oE 'alsa_output\.usb-Logitech_PRO_X[^[:space:]:]+analog-stereo' | sort -u | head -1)
          fi
          if [[ -z "$logi" ]]; then
            echo "goxlr-audio-route: no Logitech PRO X Wireless analog-stereo sink; is the dongle plugged in?" >&2
            return 1
          fi
          SRC_L="''${split}:output_AUX4"
          SRC_R="''${split}:output_AUX5"
          HW_L="alsa_output.hw_GoXLR_0:playback_AUX4"
          HW_R="alsa_output.hw_GoXLR_0:playback_AUX5"
          DST_L="''${logi}:playback_FL"
          DST_R="''${logi}:playback_FR"
          return 0
        }

        for ((i = 0; i < 90; i++)); do
          if ! resolve_ports; then
            sleep 1
            continue
          fi
          "$PW_LINK" -d "''${SRC_L}" "''${HW_L}" 2>/dev/null || true
          "$PW_LINK" -d "''${SRC_R}" "''${HW_R}" 2>/dev/null || true
          "$PW_LINK" -d "''${SRC_L}" "''${DST_L}" 2>/dev/null || true
          "$PW_LINK" -d "''${SRC_R}" "''${DST_R}" 2>/dev/null || true
          if "$PW_LINK" "''${SRC_L}" "''${DST_L}" && "$PW_LINK" "''${SRC_R}" "''${DST_R}"; then
            exit 0
          fi
          sleep 1
        done
        echo "goxlr-audio-route: failed after 90s. Check: pw-link -l | grep -E 'Headphones__sink.split|Logitech'" >&2
        exit 1
      '';
    };
  };
}
