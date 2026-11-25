{...}: {
  # agenix decrypts tracked .age files to /run/agenix at activation time.
  # This host key is the default identity used for decryption.
  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Encrypted secrets live under secrets/*.age (see secrets/secrets.nix for recipients).
  age.secrets = {
    llama-swap-api-key = {
      file = ../secrets/llama-swap-api-key.age;
      # systemd EnvironmentFile: LLAMA_SWAP_API_KEY=...
      owner = "chaton";
      group = "users";
      mode = "0400";
    };

    # EnvironmentFile for coolify-env-sync. Fill with:
    #   agenix -e secrets/coolify-token.age
    #   COOLIFY_BASE_URL=https://…
    #   COOLIFY_TOKEN=…
    coolify-token = {
      file = ../secrets/coolify-token.age;
      owner = "chaton";
      group = "users";
      mode = "0400";
    };

    # tailscale-auth-key = {
    #   file = ../secrets/tailscale-auth-key.age;
    #   mode = "0400";
    # };
  };
}
