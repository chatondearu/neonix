{ pkgs, inputs, ... }:

let
  # Single WiVRn derivation for service, OpenXR manifest, and Steam mounts.
  wivrnPkg = pkgs.wivrn.override { cudaSupport = true; };
in
{
  ## TO TEST :
  # - Stardust XR runtime https://github.com/StardustXR

  programs.adb.enable = true;

  environment.systemPackages = with pkgs; [
    wayvr # Stream your desktop to your Quest - nixpkgs-xr
    sidequest # Sideload / extra VR apps for Meta Quest (see Meta developer mode + USB/Wi-Fi)
  ];

  # OpenXR loader (WayVR, steam-run, etc.) needs this outside Steam's FHS env.
  environment.variables.XR_RUNTIME_JSON = "${wivrnPkg}/share/openxr/1/openxr_wivrn.json";
  environment.sessionVariables.XR_RUNTIME_JSON = "${wivrnPkg}/share/openxr/1/openxr_wivrn.json";

  # WiVRn is a runtime for wireless VR devices - nixpkgs-xr
  services.wivrn = {
    enable = true;
    openFirewall = true; # Required for wireless streaming
    # defaultRuntime = true; # not needed anymore by WinVrn

    package = wivrnPkg;
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
      10400 # not sure of what is behind for VR stuff
      9757
      5353
    ]; # VRLink UDP
  };
}
