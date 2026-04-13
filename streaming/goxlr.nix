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

  # wpctl status
  # pw-loopback --capture-props='node.target="alsa_input.usb-TC-Helicon_GoXLR-00.HiFi__Line4__source.monitor"' --playback-props='node.target="alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo"'

  services.pipewire.extraConfig.pipewire."99-goxlr-loopback" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "GoXLR Broadcast to Headset";
          "capture.props" = {
            "node.target" = "alsa_input.usb-TC-Helicon_GoXLR-00.HiFi__Line4__source"; # Remplacer par Line5 si le test 1 l'exige
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.target" = "alsa_output.usb-Logitech_PRO_X_Wireless_Gaming_Headset-00.analog-stereo";
            "audio.position" = [ "FL" "FR" ];
          };
        };
      }
    ];
  };
}
