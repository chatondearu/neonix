{ pkgs, ... }:

{
  # Bluetooth (disabled: no hardware adapter detected)
  hardware.bluetooth.enable = false;
  services.blueman.enable = false;

  # Power management (required by DMS and wireplumber)
  services.upower.enable = true;

  # Printing
  services.printing.enable = false;

  # Audio: PipeWire (rtkit is enabled in security.nix)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    raopOpenFirewall = true; # AirPlay/RAOP support (requires avahi)

    # Native PipeWire sink that writes audio into the snapserver FIFO.
    # Must match snapserver sampleformat: 48000:16:2
    # extraConfig.pipewire."99-snapcast" = {
    #   "context.modules" = [
    #     {
    #       name = "libpipewire-module-pipe-tunnel";
    #       args = {
    #         "tunnel.mode" = "sink";
    #         "pipe.filename" = "/run/snapcast/snapfifo";
    #         "audio.format" = "S16LE";
    #         "audio.rate" = 48000;
    #         "audio.channels" = 2;
    #         "node.name" = "Snapcast";
    #         "node.description" = "Sortie Snapcast (rAudio)";
    #       };
    #     }
    #   ];
    # };
  };

  # Pre-create the FIFO and its parent directory at boot.
  # /run is a real tmpfs shared across all namespaces (unlike /tmp which is
  # private to the snapserver service due to PrivateTmp=yes in its unit).
  # snapserver (owner "snapserver") opens it for reading.
  # PipeWire (user "chaton", group "audio") opens it for writing.
  # snapserver uses DynamicUser=yes, so its UID only exists while the service
  # runs — systemd-tmpfiles cannot resolve it at boot. Use root:root with open
  # permissions instead; both snapserver (reader) and PipeWire/chaton (writer)
  # can access the FIFO without group membership tricks.
  # systemd.tmpfiles.rules = [
  #   "d /run/snapcast 0755 root root -"
  #   "p /run/snapcast/snapfifo 0666 root root -"
  # ];

  # Audio: Snapserver
  # services.snapserver = {
  #   enable = true;
  #   openFirewall = true; # Opens ports 1704/1705

  #   settings = {
  #     http = {
  #       enabled = true;
  #       bind_to_address = "0.0.0.0";
  #       port = 1780;
  #     };

  #     stream = {
  #       # No mode=create: the FIFO is pre-created by systemd.tmpfiles above.
  #       # /run/snapcast/ is in the real /run namespace, accessible despite PrivateTmp=yes.
  #       source = [
  #         "pipe:///run/snapcast/snapfifo?name=NixOS-PC&sampleformat=48000:16:2&codec=flac"
  #       ];
  #     };
  #   };
  # };

  # Optional: local snapclient to also hear audio on this machine in sync with the RPi.
  # Remove this service if you only want to stream to the RPi without local playback.
  systemd.user.services.snapclient-local = {
    description = "Snapcast local client (loopback playback)";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.snapcast}/bin/snapclient -h ::1";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Keyboard: ZSA
  hardware.keyboard.zsa.enable = true;

  environment.systemPackages = with pkgs; [
    keymapp
  ];
}