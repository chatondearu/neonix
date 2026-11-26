{pkgs, ...}: {
  # UTC in the hardware clock (NixOS default). Local TZ disables RTC updates
  # and makes the boot clock lie until NTP — daemons that snapshot unix time at
  # start then refuse phone envelopes as stale.
  time.hardwareClockInLocalTime = false;
  time.timeZone = "Europe/Paris";
  services.timesyncd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "fr_FR.UTF-8/UTF-8"
  ];

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # Configure console keymap
  #console.keyMap = "us";
  console.useXkbConfig = true;
}
