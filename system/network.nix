{...}: {
  networking.hostName = "neo-nix";

  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    2242 # SSH
  ];
  networking.firewall.allowedUDPPorts = [
    5353 # mDNS
  ];

  services.openssh = {
    enable = true;
    ports = [2242];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
      AllowUsers = ["chaton"];
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
