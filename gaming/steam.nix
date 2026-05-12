{
  pkgs,
  config,
  ...
}: let
  # Same WiVRn build as services.wivrn (CUDA) so Steam + ~/.config/openxr match the runtime.
  wivrnPkg = config.services.wivrn.package or (pkgs.wivrn.override {cudaSupport = true;});
in {
  # WayVR / xdg-open use portal + MIME DB; register steam schemes so GTK finds Steam.
  xdg.mime.enable = true;
  xdg.mime.addedAssociations = {
    "x-scheme-handler/steam" = [
      "com.valvesoftware.Steam.desktop"
      "steam.desktop"
    ];
    "x-scheme-handler/steamlink" = [
      "com.valvesoftware.Steam.desktop"
      "steam.desktop"
    ];
  };
  xdg.mime.defaultApplications = {
    "x-scheme-handler/steam" = "com.valvesoftware.Steam.desktop";
    "x-scheme-handler/steamlink" = "com.valvesoftware.Steam.desktop";
  };

  environment.systemPackages = with pkgs; [
    opencomposite # OpenComposite is a runtime for wireless VR devices - nixpkgs-xr
    xdg-utils # Utilities for XDG (e.g. xdg-open) used by SteamVR
    protonup-qt # Proton Updater for Steam Play
  ];

  # Install Steam.
  programs.steam = let
    patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
      patches =
        (o.patches or [])
        ++ [
          ./vr/steam-vr/bwrap.patch
        ];
    });
  in {
    enable = true;
    gamescopeSession.enable = true;

    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    protontricks.enable = true;

    package = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          libkrb5
          keyutils
        ];

      extraProfile = ''
        # Fixes timezones on VRChat
        unset TZ

        # Import host OpenXR runtimes inside Pressure Vessel (Steam runtime).
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1

        export PROTON_LOG=1

        # Prefixes are kept on a Linux filesystem through a bind mount
        # declared in system/boot.nix (/games/.../compatdata -> ~/.local/.../compatdata).
        export STEAM_COMPAT_MOUNTS="${wivrnPkg}:${pkgs.opencomposite}"
      '';

      extraEnv = {
        OBS_VKCAPTURE = true;
        ENABLE_VKBASALT = "1";

        XR_RUNTIME_JSON = "${wivrnPkg}/share/openxr/1/openxr_wivrn.json";
        # Force Steam/SteamVR Qt apps to use XWayland plugin only.
        # This avoids vrmonitor crashes when Wayland Qt plugin is unavailable.
        QT_QPA_PLATFORM = "xcb";

        # activated in gpu.nix for screen sharing (Nvidia + Wayland)
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      # Patching bubblewrap to allow capabilities for steamVR (required)
      buildFHSEnv = (
        args: (
          (pkgs.buildFHSEnv.override {
            bubblewrap = patchedBwrap;
          })
          (
            args
            // {
              extraBwrapArgs = (args.extraBwrapArgs or []) ++ ["--cap-add ALL"];
            }
          )
        )
      );
    };

    extraCompatPackages = with pkgs; [proton-ge-bin proton-ge-rtsp-bin];
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

  users.users.chaton.maid = let
    # OpenVR shim -> OpenXR (WiVRn). Store path updates on rebuild; never hand-edit in ~/.config.
    openCompositeRuntime = "${pkgs.opencomposite}/lib/opencomposite";
  in {
    file.xdg_config."openxr/1/active_runtime.json".source = "${wivrnPkg}/share/openxr/1/openxr_wivrn.json";
    file.xdg_config."openvr/openvrpaths.vrpath".text = let
      steam = "${config.users.users.chaton.home}/.steam/steam";
    in
      builtins.toJSON {
        version = 1;
        jsonid = "vrpathreg";
        external_drivers = null;
        config = ["${steam}/config"];
        log = ["${steam}/logs"];
        # OpenComposite-first: OpenVR games use WiVRn via OpenXR without starting SteamVR.
        # For stubborn titles, install SteamVR and temporarily point runtime to SteamVR.
        runtime = [openCompositeRuntime];
      };
    file.xdg_config."wivrn/config.json".text = builtins.toJSON {
      debug-gui = false;
      hid-forwarding = false;
      use-steamvr-lh = false;
      "openvr-compat-path" = openCompositeRuntime;
    };
  };

  # Set capabilities for SteamVR binaries
  # to avoid steamVR to claim sudo at each start use this :
  # `sudo setcap CAP_SYS_NICE=eip ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher`
  systemd.services.set-steam-vr-capabilities = {
    description = "Set capabilities for SteamVR binaries";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
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
