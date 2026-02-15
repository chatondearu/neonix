{ ... }:

{
  networking.hostName = "neo-nix";

  # Enable networking
  networking.networkmanager.enable = true;

  # SSH configuration with security hardening
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  # Network Service Discovery for mDNS (avahi-daemon). Seems to be needed by mDNS.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}