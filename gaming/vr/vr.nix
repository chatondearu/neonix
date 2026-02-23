{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wayvr # Stream your desktop to your Quest - nixpkgs-xr
  ];

  # WiVRn is a runtime for wireless VR devices - nixpkgs-xr
  services.wivrn = {
    enable = true;
    openFirewall = true; # Required for wireless streaming
    defaultRuntime = true;

    package = (pkgs.wivrn.override { cudaSupport = true; });
  };

  # Device rules for VR headsets
  services.udev.extraRules = ''
    # Meta Quest VR headsets (Quest 1, 2, 3)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2833", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2833", MODE="0666"

    # Valve Index and other VR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2d40", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2d40", MODE="0666"
  '';

  # Login limits for VR (realtime priority, nice, memory lock)
  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@users";
      item = "nice";
      type = "-";
      value = "-11";
    }
    {
      domain = "@users";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
  ];

  # Firewall rules for VR streaming
  networking.firewall = {
    allowedTCPPorts = [
      27062
      9757
    ]; # SteamVR web interface
    allowedUDPPorts = [
      10400
      9757
      5353
    ]; # VRLink UDP
  };
}
