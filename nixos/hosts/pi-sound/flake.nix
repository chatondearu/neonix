{
  description = "Pi Zero 2 W audio player — Merus I2S & Squeezelite";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixos-raspberrypi.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-raspberrypi,
    ...
  }: let
    piSoundModules = [
      {
        imports = with nixos-raspberrypi.nixosModules; [
          raspberry-pi-02.base
        ];
      }
      ./configuration.nix
    ];

    piSoundImageModules =
      piSoundModules
      ++ [
        {
          imports = [nixos-raspberrypi.nixosModules.sd-image];
          sdImage.compressImage = false;
          # nixpkgs marks the ext4 partition bootable (U-Boot path). With
          # boot.loader.raspberry-pi.bootloader = "kernel", the FAT firmware
          # partition must be MBR-active or the Pi reports "partition not FAT".
          sdImage.postBuildCommands = ''
            sfdisk --no-reread --no-tell-kernel "$img" -A 2
            sfdisk --no-reread --no-tell-kernel "$img" -A 1
          '';
        }
      ];
  in {
    nixosConfigurations.pi-sound = nixos-raspberrypi.lib.nixosSystem {
      modules = piSoundModules;
    };

    packages.aarch64-linux.sdImage =
      (nixos-raspberrypi.lib.nixosSystem {
        modules = piSoundImageModules;
      }).config.system.build.sdImage;
  };
}
