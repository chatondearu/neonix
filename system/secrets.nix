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
  };
}
