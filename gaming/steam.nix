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

      package = pkgs.steam.override {
        extraProfile = ''
          # Fixes timezones on VRChat
          unset TZ
          # Allows Monado to be used for VR
          export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
        '';
        
        extraEnv = {
          OBS_VKCAPTURE = true;
          ENABLE_VKBASALT = "1";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";

          # For VR
          VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
          PRESSURE_VESSEL_FILESYSTEMS_RO = "/nix/store";
          QT_QPA_PLATFORM = "xcb";
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
        steam = "${config.users.users.chaton.home}/Steam";
      in builtins.toJSON {
        version = 1;
        jsonid = "vrpathreg";
        external_drivers = null;
        config = [ "${steam}/config" ];
        log = [ "${steam}/logs" ];
        runtime = [ "${pkgs.opencomposite}/lib/opencomposite" ];
      };
  };
}
