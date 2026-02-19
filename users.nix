{ ... }:

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
    ];
  };
}
