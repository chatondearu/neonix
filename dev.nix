{ pkgs, ... }:
let
  secrets = import ./secrets.nix;
in
{

  environment.systemPackages = with pkgs; [
    git
    gh
    lazygit
    android-tools # For ADB (uaccess handled by systemd 258)
    # Flake uses nixos-unstable, so these are already unstable packages
    unstable.cursor-cli
    unstable.code-cursor
  ];

  programs.git = {
    enable = true;
    config = {
      user = {
        name  = secrets.githubUser;
        email = secrets.githubEmail;
      };
      init.defaultBranch = "main";
    };
  };

  virtualisation.docker.enable = true;
  # programs.adb no longer needed as systemd 258 handles uaccess rules automatically
}