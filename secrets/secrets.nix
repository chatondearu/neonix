let
  # Replace these placeholders with your real AGE public keys.
  # Host key (from `age-keygen -y /path/to/key.txt` or SSH->AGE conversion)
  hostKey = "age1replace-this-with-host-public-key";
  userKey = "age1replace-this-with-user-public-key";

  recipients = [hostKey userKey];
in
{
  # Example:
  # "github-token.age".publicKeys = recipients;
}
