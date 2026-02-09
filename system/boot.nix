{ ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Removing the swap partition from luks to make an auto generated encryption key
  # boot.initrd.luks.devices."luks-83f2f902-73e0-46cd-8cde-77d721c363b9".device = "/dev/disk/by-uuid/83f2f902-73e0-46cd-8cde-77d721c363b9";

  # Configure console keymap
  console.keyMap = "us";
}
