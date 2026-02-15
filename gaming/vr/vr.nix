{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    android-tools # Android tools for debugging and development
    wayvr # Great way to stream your desktop to your Quest (from nixos-unstable)
  ];

   ## VR

  # ADB no longer needs programs.adb.enable as systemd 258 handles uaccess rules automatically
  # android-tools package is already in systemPackages above

  # WiVRn is a runtime for wireless VR devices
  services.wivrn = {
    enable = true;
    openFirewall = true; # Required for wireless streaming
    defaultRuntime = true;

    package = (pkgs.wivrn.override { cudaSupport = true; });
  };

  # Devicess rules for VR
  services.udev.extraRules = ''
    # Meta Quest VR headsets (Quest 1, 2, 3)
    # Vendor ID 2833 = Oculus/Meta
    # Product IDs: 0183 (Quest 1), 0186 (Quest 1 in file transfer mode), 
    #              01a0 (Quest 2), 01a1 (Quest 2 in file transfer mode),
    #              0360 (Quest 3), 0361 (Quest 3 in file transfer mode)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2833", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2833", MODE="0666"

    # Valve Index and other VR devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2d40", MODE="0666"
    SUBSYSTEM=="usb_device", ATTRS{idVendor}=="2d40", MODE="0666"
  '';

  # Login limits for VR
  security.pam.loginLimits = [
    { domain = "@users"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@users"; item = "nice"; type = "-"; value = "-11"; }
    { domain = "@users"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  systemd.services.set-steam-vr-capabilities = {
    description = "Set capabilities for SteamVR binaries";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Attendre que Steam soit installé
      sleep 2
      # Trouver et configurer les binaries SteamVR
      for user_home in /home/*; do
        steamvr_path="$user_home/.local/share/Steam/steamapps/common/SteamVR"
        if [ -d "$steamvr_path" ]; then
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrcompositor" 2>/dev/null || true
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrserver" 2>/dev/null || true
        fi
      done
    '';
  };

  # Pipewire for audio and video for VR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # Important pour Steam
    pulse.enable = true;
    wireplumber.enable = true;  # Gestionnaire de session
  };
  networking.firewall = {
    allowedTCPPorts = [ 27062 ];  # SteamVR web interface
    allowedUDPPorts = [ 10400 ];  # VRLink UDP
  };
}