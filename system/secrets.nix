{...}: {
  # agenix decrypts tracked .age files to /run/agenix at activation time.
  # This host key is the default identity used for decryption.
  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Add encrypted secrets here, for example:
  # age.secrets.github-token.file = ../secrets/github-token.age;
  age.secrets = {};
}
