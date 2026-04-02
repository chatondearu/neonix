{ ... }:

{
  networking.hostName = "neo-nix";

  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    2242  # SSH
    8009  # TCP SYN
    9000  # UPnP control ports (dynamic, opened via conntrack normally)
  ];
  networking.firewall.allowedUDPPorts = [
    8009  # UDP SYN
    5353  # mDNS
  ];

  networking.firewall.allowedUDPPortRanges = [
    { from = 32768; to = 61000; }  # SSDP discovery (sblast)
  ];

  services.openssh = {
    enable = true;
    ports = [ 2242 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
      AllowUsers = [ "chaton" ];
    };
    openFirewall = true;
  };

  # mDNS + UPnP/DLNA discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # ouvre automatiquement 5353/udp
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };
}