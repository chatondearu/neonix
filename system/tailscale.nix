# Tailscale client on neo-nix, aimed at a self-hosted Headscale control plane.
#
# First join (once Headscale is up):
#   headscale preauthkeys create --user <user> --expiration 1h
#   sudo tailscale up --login-server=https://YOUR_HEADSCALE --authkey=tskey-...
#
# Fully declarative join: create secrets/tailscale-auth-key.age (agenix), then uncomment
# authKeyFile + extraUpFlags below and rebuild.
{
  config,
  ...
}: let
  # Headscale control plane (must match `tailscale debug prefs` ControlURL).
  headscaleLoginServer = "https://headscale.neomatix.net";
in {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "none";

    # Keep LAN DNS (Pi-hole on the Synology NAS, local *.home via reverse proxy).
    # Without this, `tailscale up` can push Headscale/MagicDNS and break local names.
    extraSetFlags = ["--accept-dns=false"];

    # After agenix secret (see comment in system/secrets.nix):
    # authKeyFile = config.age.secrets.tailscale-auth-key.path;
    # extraUpFlags = [
    #   "--login-server=${headscaleLoginServer}"
    #   "--accept-dns=false"
    # ];
  };
}
