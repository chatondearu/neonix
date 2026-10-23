# Sunshine (GameStream host) + Moonlight Qt (client) — pair Moonlight with this machine's Sunshine.
{pkgs, lib, ...}: {
  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];

  # Web UI: https://localhost:47990/
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;

    package = pkgs.sunshine.override {
      cudaSupport = true;
    };

    settings = {
      sunshine_name = "Neonix";
      # Disable AV1 encoding, not supported by my GPU <= RTX 4000
      av1_mode = 1;
      # wlgrab picks monitor 0 (DP-1) by default; stream the left niri output (DP-2 @ x=0)
      output_name = "DP-2";
      keyboard = true;
      # Keep Right Alt as AltGr on AZERTY; do not remap to Super (breaks AltGr and some Moonlight Alt chords).
      key_rightalt_to_key_win = false;
    };
  };

  # Sunshine may start before niri exposes a GTK-friendly display, causing
  # gtk_widget_get_scale_factor assertion warnings at boot.
  systemd.user.services.sunshine = {
    unitConfig.After = lib.mkAfter ["graphical-session.target" "pipewire.service"];
    unitConfig.Wants = ["graphical-session.target"];
    unitConfig.ConditionUser = "!dms-greeter";
    serviceConfig.Environment = ["GDK_BACKEND=wayland"];
  };

  networking.firewall = {
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ]; # Sunshine web interface
  };

  networking.firewall.allowedUDPPortRanges = [
    {
      from = 47998;
      to = 48000;
    } # Sunshine UDP
  ];
}
