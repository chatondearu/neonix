{pkgs, ...}: let
  secrets = import ./../secrets.nix;
in {
  environment.systemPackages = with pkgs; [
    git
    gh
    lazygit
    android-tools # For ADB (uaccess handled by systemd 258)

    # Flake uses nixos-unstable, so these are already unstable packages
    (pkgs.unstable.callPackage ../pkgs/cursor/default.nix { })
  ] ++ (with unstable; [
    cursor-cli

    godot
    godot-mcp
    pixelorama

    #TODO add Crocotile, itch.io
  ]);

  programs.git = {
    enable = true;
    config = {
      user = {
        name = secrets.githubUser;
        email = secrets.githubEmail;
      };

      safe.directory = "/etc/nixos";
      init.defaultBranch = "main";
    };

    settings = {
      push = { autoSetupRemote = true; };
    };
  };

  imports = [
    ./docker.nix
    ./ai.nix
    ./helix.nix
    ./direnv.nix
  ];
}
