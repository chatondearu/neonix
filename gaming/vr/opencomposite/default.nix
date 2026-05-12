{
  pkgs,
  self,
  ...
}: let
  ocLaunch = pkgs.writeShellApplication {
    name = "oc-launch";
    runtimeInputs = with pkgs; [coreutils findutils gawk gnused gnugrep];
    text = builtins.readFile ./oc-launch.sh;
  };
in {
  environment.systemPackages = [ocLaunch];

  users.users.chaton.maid = {
    file.xdg_config."opencomposite/global/opencomposite.ini".source = "${self}/gaming/vr/opencomposite/global/opencomposite.ini";

    file.xdg_config."opencomposite-games".source = "{{home}}/etc/nixos/gaming/vr/opencomposite/games";
  };
}
