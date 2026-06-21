{
  description = "NixOS configuration with niri and waybar";

  inputs = {
    # NixOS official package sources
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Alejandra formatter
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    # nix-maid
    nix-maid.url = "github:viperML/nix-maid";
    agenix.url = "github:ryantm/agenix";

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

    # nixpkgs-xr
    nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";

    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    nirinit.url = "github:amaanq/nirinit";
    nirinit.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
    nix-maid,
    agenix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    pkgsCuda = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.cudaSupport = true;
    };
  in {
    packages.${system} = {
      goxlr-router = pkgs.callPackage ./pkgs/goxlr-router {};

      # Build separately: nix build .#llama-cpp-cuda  (slow CUDA compile)
      llama-cpp-cuda = pkgsCuda.callPackage ./pkgs/llama-cpp/default.nix {
        inherit (pkgsCuda) llama-cpp;
      };
    };

    nixosConfigurations = {
      neo-nix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs self;
        };
        modules = [
          # Alejandra formatter
          {
            environment.systemPackages = [
              alejandra.defaultPackage.${system}
              agenix.packages.${system}.default
              #self.packages.${system}.rtk
            ];
          }

          nix-maid.nixosModules.default
          agenix.nixosModules.default

          # NixOS configuration
          ./configuration.nix
        ];
      };
    };
  };
}
