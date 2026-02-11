{ ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Removing the swap partition from luks to make an auto generated encryption key
  # boot.initrd.luks.devices."luks-83f2f902-73e0-46cd-8cde-77d721c363b9".device = "/dev/disk/by-uuid/83f2f902-73e0-46cd-8cde-77d721c363b9";

  # Configure console keymap
  console.keyMap = "us";

  fileSystems."/games" = {
    device = "/dev/disk/by-partuuid/fac02d23-340d-499a-8a90-3c799fa1a3c6";
    fsType = "ntfs";
    options = [
      "nofail" # Allows system to continue to boot if drive cannot be mounted
      "users" # Allows any user to mount/unmount
      "exec" # Allows execution of files
      "uid=1000,gid=100" # Allows the user to mount/unmount
    ];
  };
}
