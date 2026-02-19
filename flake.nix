{
  description = "NixOS configuration with niri and waybar";

  inputs = {
    # NixOS official package sources
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Alejandra formatter
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    # nix-maid
    nix-maid.url = "github:viperML/nix-maid";

    # quickshell
    quickshell.url = "git+https://git.outfoxxed.me/quickshell/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    # dms
    dms.url = "github:AvengeMedia/DankMaterialShell/stable";
    dms.inputs.nixpkgs.follows = "nixpkgs";

    # dms-plugin-registry
    dms-plugin-registry.url = "github:AvengeMedia/dms-plugin-registry";
    dms-plugin-registry.inputs.nixpkgs.follows = "nixpkgs";

    # Affinity v3 (Designer, Photo, Publisher) via Wine
    affinity-nix.url = "github:mrshmllow/affinity-nix";
  };

  outputs = { 
    self,
    nixpkgs,
    alejandra,
    nix-maid,
    ...
  } @inputs: let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      neo-nix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [

          # Alejandra formatter
          {
            environment.systemPackages = [alejandra.defaultPackage.${system}];
          }

          nix-maid.nixosModules.default

          # NixOS configuration
          ./configuration.nix
        ];
      };
    };
  };
}