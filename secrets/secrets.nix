let
  # Host identity (ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub)
  hostKey = "age1ywj43me8kzavjq39ld3h76ccf7wqxe0kly9lpkdh6nk7qytwkf8s7pl09d";

  recipients = [hostKey];
in {
  "llama-swap-api-key.age".publicKeys = recipients;
}
