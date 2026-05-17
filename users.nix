{ lib, pkgs, ... }:

{
  users.users.chaton = {
    isNormalUser = true;
    description = "Chaton";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "video"
      "input"
      "greeter"
      "docker"
      "audio"
      "render"
      # Polkit allows GameMode pkexec helpers only for this group (see gamemode.rules).
      "gamemode"
    ];
  };

  environment.etc."accounts-service/users/chaton".text = ''
    [User]
    Icon=/var/lib/AccountsService/icons/chaton
    SystemAccount=false
  '';

  systemd.tmpfiles.rules = [
    "L /var/lib/AccountsService/icons/chaton - - - - ${./assets/avatar.png}"
    "L /home/chaton/.face.icon - - - - ${./assets/avatar.png}"
  ];
}
