{pkgs, ...}: {
  virtualisation.docker.enable = false;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    extraPackages = with pkgs; [podman-compose];
  };

  virtualisation.containers.storage.settings.storage = {
    driver = "overlay";
    graphroot = "/hdd/docker";
    runroot = "/run/containers/storage";
  };

  systemd.tmpfiles.rules = [
    "d /hdd/docker 0710 root root -"
  ];

  systemd.services.podman = {
    after = ["hdd.mount"];
    requires = ["hdd.mount"];
  };
  systemd.sockets.podman = {
    after = ["hdd.mount"];
    requires = ["hdd.mount"];
  };
}
