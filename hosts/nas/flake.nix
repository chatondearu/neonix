{
  description = "Synology NAS — declarative Docker stacks deployed from neo-nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = inputs @ {self, nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    hostsNas = ./.;
  in {
    packages.${system} = {
      nas-deploy = pkgs.writeShellApplication {
        name = "nas-deploy";
        runtimeInputs = with pkgs; [bash openssh rsync coreutils];
        text = ''
          export HOSTS_NAS_ROOT='${hostsNas}'
          exec ${hostsNas}/scripts/deploy.sh
        '';
      };

      nas-bootstrap-remote = pkgs.writeShellApplication {
        name = "nas-bootstrap-remote";
        runtimeInputs = with pkgs; [bash openssh coreutils];
        text = ''
          export HOSTS_NAS_ROOT='${hostsNas}'
          exec ${hostsNas}/scripts/bootstrap-remote.sh
        '';
      };
    };

    apps.${system} = {
      deploy = {
        type = "app";
        program = "${self.packages.${system}.nas-deploy}/bin/nas-deploy";
      };
      bootstrap = {
        type = "app";
        program = "${self.packages.${system}.nas-bootstrap-remote}/bin/nas-bootstrap-remote";
      };
    };
  };
}
