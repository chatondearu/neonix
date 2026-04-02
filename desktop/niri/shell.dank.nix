{ pkgs, inputs, ... }:

{
  # DANK LINUX - https://danklinux.com/docs/dankmaterialshell/nixos
  
  imports = [
    # Import the dms-shell module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/dms-shell.nix"
    inputs.dms-plugin-registry.modules.default
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
      enable = true;             # Systemd service for auto-start
      restartIfChanged = true;   # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    enableVPN = true;                  # VPN management widget
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = true;       # Calendar integration (khal)
    enableClipboardPaste = true;       # Clipboard paste (wtype)

    plugins = {
      dockerManager.enable = true;
    };
  };

  # Strip trailing whitespace-only lines from .desktop files (SteamVR generates
  # broken entries that cause quickshell desktop-entry parser to flood warnings
  # and can trigger a crash in QObjectWrapper::wrap_slowPath)
  systemd.user.services.fix-desktop-entries = {
    description = "Fix malformed .desktop files";
    wantedBy = [ "graphical-session.target" ];
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
}