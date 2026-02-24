# VR Guide
see : https://lvra.gitlab.io/docs/distros/nixos/

# TODO

to avoid steamVR to claim sudo at each start use this :
`sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher`

before we used this in nix config file :
```
# Set capabilities for SteamVR binaries
  systemd.services.set-steam-vr-capabilities = {
    description = "Set capabilities for SteamVR binaries";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for Steam to be available
      sleep 2
      # Find and configure SteamVR binaries
      for user_home in /home/*; do
        steamvr_path="$user_home/.local/share/Steam/steamapps/common/SteamVR"
        if [ -d "$steamvr_path" ]; then
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrcompositor" 2>/dev/null || true
          ${pkgs.libcap}/bin/setcap 'cap_sys_nice+eip' "$steamvr_path/bin/linux64/vrserver" 2>/dev/null || true
        fi
      done
    '';
  };
```

## Optional: Auto-Restart Script

The startvr script here is meant to make launching SteamVR less tedious.

It can be used with both ALVR and wired headsets.

What it does:

    Whitelist drivers for SpaceCal and ALVR so these will never get blocked
    Apply bindings spam patch by Plyshka
    Setcap the compositor after a SteamVR update
    Start SteamVR and restart it for you in case of a crash
    Prevent SteamVR processes from getting stuck and putting SteamVR in an inconsistent state


## Optional: Disable SteamVR dashboard

The SteamVR dashboard has some major issues with high CPU usage, occasional freezing and sometimes going completely unresponsive.

Many choose to disable SteamVR dashboard and instead use something like WayVR’s built-in dashboard for desktop & game library access.

To do this, simply remove the execute permission from vrwebhelper:

`chmod -x ~/.steam/steam/steamapps/common/SteamVR/bin/vrwebhelper/linux64/vrwebhelper`

(To re-enable, run the same command but with +x instead of -x.)