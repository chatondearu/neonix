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
  # Public HTTPS URL of your Headscale instance (no trailing slash).
  headscaleLoginServer = "https://headscale.example.com";
in {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "none";

    # After agenix secret (see comment in system/secrets.nix):
    # authKeyFile = config.age.secrets.tailscale-auth-key.path;
    # extraUpFlags = [
    #   "--login-server=${headscaleLoginServer}"
    #   "--accept-dns=false"
    # ];
  };
}
