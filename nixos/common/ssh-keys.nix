# SSH public keys for all machines
let
  userKeys = {
    neonix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHY7kYbN0NfppTuPoP6WwKZ69L5VEN1hn8LlPVrObMBG";
  };
in
{
  inherit userKeys;
  sshKeys = builtins.attrValues userKeys;
}