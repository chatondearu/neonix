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

  # Monado is a runtime for VR devices
  #services.monado = {
  #  enable = true;
  #  defaultRuntime = true;
  #};

  #systemd.user.services.monado = {
  #  environment = {
  #    STEAMVR_LH_ENABLE = "1";
  #    XRT_COMPOSITOR_COMPUTE = "1";
  #    XRT_COMPOSITOR_FORCE_XCB = "1"; # Force the use of XCB
   #   IPC_EXIT_ON_DISCONNECT = "1"; # Exit the application when the connection to the device is lost
  #    U_PACING_COMP_MIN_TIME_MS = "5"; # Minimum time for the compositor to render the frame

   #   DXRT_ENABLE_GPL = "1"; # Enable GPL
   #   DXRT_BUILD_DRIVER_QUEST_LINK = "1"; # Build the driver question link

   #   #WMR_HANDTRACKING = "0"; # Disable hand tracking
  #  };

  #  serviceConfig = {
  #    Nice = 20; # Low priority for the service
  #  };
  #};

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
}