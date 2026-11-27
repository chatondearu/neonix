{
  pkgs,
  inputs,
  self,
  ...
}: {
  # DANK LINUX - https://danklinux.com/docs/dankmaterialshell/nixos

  # Disable the stable dms-shell module (nixos-26.05 still uses this filename)
  disabledModules = ["programs/wayland/dms-shell.nix"];

  imports = [
    # Unstable renamed the file to dux-shell.nix; programs.dms-shell still aliases
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/dux-shell.nix"
    inputs.dms-plugin-registry.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    dgop # System monitoring widgets
    matugen # automatic color shemes generation from wallpaper on dms
    cava # audio visualizer
    khal # calendar integration
    cliphist # clipboard history manager
    wl-clipboard # clipboard manager
    wtype # Wayland clipboard paste

    # QtMultimedia backend for DMS sound effects
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];

  programs.dms-shell = {
    enable = true;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;

    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    # VPN, matugen/cava, and calendar backends are handled by DMS at runtime
    # (see unstable dux-shell module); khal/matugen/cava stay in systemPackages.
  };

  # Strip trailing whitespace-only lines from .desktop files (SteamVR generates
  # broken entries that cause quickshell desktop-entry parser to flood warnings
  # and can trigger a crash in QObjectWrapper::wrap_slowPath)
  # Do not auto-start the full desktop shell under the greeter user session.
  systemd.user.services.dms.unitConfig.ConditionUser = "!dms-greeter";

  systemd.user.services.fix-desktop-entries = {
    description = "Fix malformed .desktop files";
    wantedBy = ["graphical-session.target"];
    unitConfig.ConditionUser = "!dms-greeter";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fix-desktop-entries" ''
        dir="$HOME/.local/share/applications"
        [ -d "$dir" ] || exit 0
        for f in "$dir"/*.desktop; do
          [ -f "$f" ] || continue
          if ${pkgs.gnugrep}/bin/grep -Pq '^\s+$' "$f"; then
            ${pkgs.gnused}/bin/sed -i '/^\s*$/d' "$f"
          fi
        done
      '';
    };
  };

  users.users.chaton.maid = {
    # DMS stable files (keep settings.json unmanaged for runtime edits via UI).
    file.xdg_config."DankMaterialShell/plugin_settings.json".source = "${self}/desktop/dank-material-shell/plugin_settings.json";
    file.xdg_config."DankMaterialShell/plugins/DictationPtt".source = "${self}/desktop/dank-material-shell/plugins/DictationPtt";
    file.xdg_config."DankMaterialShell/firefox.css".source = "${self}/desktop/dank-material-shell/firefox.css";
    file.xdg_config."DankMaterialShell/zen.css".source = "${self}/desktop/dank-material-shell/zen.css";
  };
}
