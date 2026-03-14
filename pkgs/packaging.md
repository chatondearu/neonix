To see what is inside a .deb before installing it in nixos :

```bash
nix-shell -p dpkg
dpkg -c ./application-name.deb
```