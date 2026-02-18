{ ... }:

{
  # Bluetooth (disabled: no hardware adapter detected)
  hardware.bluetooth.enable = false;
  services.blueman.enable = false;

  # Power management (required by DMS and wireplumber)
  services.upower.enable = true;

  # Printing
  services.printing.enable = false;

  # Audio: PipeWire (rtkit is enabled in security.nix)
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # Advanced audio routing (DMS audio features)
  };
}
