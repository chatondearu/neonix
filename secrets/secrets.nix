let
  # Host SSH key, not its ssh-to-age form: age.identityPaths uses the SSH key,
  # which only matches ssh-ed25519 recipients.
  hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/GkbDE0YJJJXTe2hG4SP+LdC7gfK4ON3JEYn6arEXL";

  recipients = [hostKey];
in {
  "llama-swap-api-key.age".publicKeys = recipients;
  "coolify-token.age".publicKeys = recipients;
}
