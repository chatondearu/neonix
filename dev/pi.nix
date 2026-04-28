{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  ];

  users.users.chaton.maid = {
    file.xdg_config."opencode/opencode.json".source = "{{home}}/etc/nixos/dev/opencode/opencode.json";
  };
}
