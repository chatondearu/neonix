### Before buil

you need to check some things :

- get the correct path for the SD-card: `lsblk`
- check the disponnibility of age : `nix-shell -p age --run "age --version"`
- have a publique ssh key on the build host: `cat ~/.ssh/id_ed25519.pub`

## Build with Nix

you need to use the flag --impure with flakes

`nix build .#sdImage --impure`