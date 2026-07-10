{
  pkgs,
  lib,
  ...
}: {
  # Bluetooth (disabled: no hardware adapter detected).
  # mkForce overrides hardware.xpadneo (nixos-26.05 module enables bluetooth);
  # the Xbox controller here uses the proprietary wireless dongle, not bluetooth.
  hardware.bluetooth.enable = lib.mkForce false;
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

    # pipewire-pulse "setsockopt(SO_PRIORITY) failed" is a benign upstream warning on 1.6.x
    # when Pulse clients connect over UNIX sockets; safe to ignore if audio works.
  };

  # Keyboard: ZSA
  hardware.keyboard.zsa.enable = true;

  environment.systemPackages = with pkgs; [
    keymapp
  ];
}
