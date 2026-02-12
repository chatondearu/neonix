# Gaming setup instructions

# Steam 

to see : https://discourse.nixos.org/t/unable-to-add-new-library-folder-to-steam/38923

## VR

### Monado OpenXR runtime

to launch monado execute :
```shell
systemctl --user start monado.service

journalctl --user --follow --unit monado.service
```

### WayVR

see : https://github.com/wlx-team/wayvr?tab=readme-ov-file