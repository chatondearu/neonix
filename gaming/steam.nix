{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    opencomposite # OpenComposite is a runtime for wireless VR devices - nixpkgs-xr
    xdg-utils # Utilities for XDG (e.g. xdg-open) used by SteamVR
    protonup-qt # Proton Updater for Steam Play
  ];

  # Install Steam.
  programs.steam =
    let
      patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [
          ./vr/steam-vr/bwrap.patch
        ];
      });
    in
    {
      enable = true;
      gamescopeSession.enable = true;

      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      protontricks.enable = true;

      package = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          libkrb5
          keyutils
        ];

        extraProfile = ''
          # Fixes timezones on VRChat
          unset TZ

          # Allows Monado to be used for VR
          #export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1

          export PROTON_LOG=1

          export STEAM_COMPAT_DATA_PATH="${config.users.users.chaton.home}/.local/share/Steam/compatdata_ntfs"

          export STEAM_COMPAT_MOUNTS="${pkgs.wivrn}:${pkgs.opencomposite}"
        '';
        
        extraEnv = {
          OBS_VKCAPTURE = true;
          ENABLE_VKBASALT = "1";

          XR_RUNTIME_JSON = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";

          # activated in gpu.nix for screen sharing (Nvidia + Wayland)
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        };

        # Patching bubblewrap to allow capabilities for steamVR (required)
        buildFHSEnv = (
          args:
          (
            (pkgs.buildFHSEnv.override {
              bubblewrap = patchedBwrap;
            })
            (
              args
              // {
                extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--cap-add ALL" ];
              }
            )
          )
        );
      };

      extraCompatPackages = with pkgs; [ proton-ge-bin proton-ge-rtsp-bin ];
    };

  # Issues with adding steam library on new disk
  # to add it manualy : '$ steam steam://open/console'
  # then in the steam console tab : 'library_folder_add /games/SteamLibrary'
  # issue solved : do not use exfat filesystem for the steam library !

  # Hardware support for devices
  #hardware.steam-hardware.enable = true; # implicitly enabled by steam package

  services.udev.extraRules = ''
    # Steam Deck controllers
    SUBSYSTEM=="input", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="3106", MODE="0660", GROUP="input"
  '';

  users.users.chaton.maid = {
    file.xdg_config."openxr/1/active_runtime.json".source = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
    file.xdg_config."openvr/openvrpaths.vrpath".text = let
        steam = "${config.users.users.chaton.home}/.steam/steam";
      in builtins.toJSON {
        version = 1;
        jsonid = "vrpathreg";
        external_drivers = null;
        config = [ "${steam}/config" ];
        log = [ "${steam}/logs" ];
        runtime = [ "${pkgs.opencomposite}/lib/opencomposite" ];
      };
  };

  # Set capabilities for SteamVR binaries
  # to avoid steamVR to claim sudo at each start use this :
  # `sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher`
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
}
