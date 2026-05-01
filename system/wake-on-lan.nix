# Wake-on-LAN via ethtool
{ pkgs, ... }:

{
  systemd.services.wake-on-lan = {
    description = "Enable Wake-on-LAN";
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp5s0 wol g";
    };
  };
}