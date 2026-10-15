{pkgs, ...}: {
  # Enable Docker
  virtualisation.docker.enable = true;

  # Bridge NAT needs host forwarding (nixpkgs also sets conf.*.forwarding).
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
}
