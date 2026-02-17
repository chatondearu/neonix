{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wayvr # Stream your desktop to your Quest
  ];

  # WiVRn is a runtime for wireless VR devices
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
    { domain = "@users"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@users"; item = "nice"; type = "-"; value = "-11"; }
    { domain = "@users"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  # Set capabilities for SteamVR binaries
  systemd.services.set-steam-vr-capabilities = {
    description = "Set capabilities for SteamVR binaries";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for Steam to be available
      sleep 2
      # Find and configure SteamVR binaries
      for user_home in /home/*; do
        steamvr_path="$user_home/.local/share/Steam/steamapps/common/SteamVR"
        if [ -d "$steamvr_path" ]; then
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrcompositor" 2>/dev/null || true
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrserver" 2>/dev/null || true
        fi
      done
    '';
  };

  # Firewall rules for VR streaming
  networking.firewall = {
    allowedTCPPorts = [ 27062 ]; # SteamVR web interface
    allowedUDPPorts = [ 10400 ]; # VRLink UDP
  };
}
