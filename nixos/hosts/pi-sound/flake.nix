{
  description = "RPi2 Audio Player - Merus I2S & Squeezelite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
  };

  outputs = { self, nixpkgs, nixos-hardware }: {
    packages.armv7l-linux.sdImage =
      let
        system = "x86_64-linux";
        # system = "armv7l-linux";
      in
      (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.crossSystem.system = "armv7l-linux"; }
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix"
          nixos-hardware.nixosModules.raspberry-pi-2
          ./configuration.nix
        ];
      }).config.system.build.sdImage;
  };
}