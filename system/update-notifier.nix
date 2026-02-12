{ config, pkgs, ... }:

let
  # Script to check for updates and notify the user
  update-checker = pkgs.writeShellScript "nixos-update-checker" ''
    # Check if updates are available
    export PATH=${pkgs.nix}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH
    
    # Update channel info without installing
    ${pkgs.nix}/bin/nix-channel --update 2>/dev/null || true
    
    # Check for system updates
    UPDATES=$(${pkgs.nix}/bin/nix-env -u --dry-run 2>&1 | ${pkgs.gnugrep}/bin/grep -c "would be" || echo "0")
    
    # Check if there are package updates by comparing channels
    STABLE_UPDATES=$(${pkgs.nix}/bin/nix-channel --list | ${pkgs.gnugrep}/bin/grep nixos)
    UNSTABLE_UPDATES=$(${pkgs.nix}/bin/nix-channel --list | ${pkgs.gnugrep}/bin/grep unstable || echo "")
    
    if [ "$UPDATES" -gt "0" ] || [ -n "$UNSTABLE_UPDATES" ]; then
      # Send notification to user
      DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        ${pkgs.libnotify}/bin/notify-send \
        -u normal \
        -i system-software-update \
        "NixOS Updates Available" \
        "Des mises à jour sont disponibles.\nUtilisez 'neo-update' pour mettre à jour le système."
    fi
  '';
in
{
  # Systemd user service to check for updates
  systemd.user.services.nixos-update-notifier = {
    description = "Check for NixOS updates and notify user";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${update-checker}";
    };
  };

  # Timer to run the update checker daily
  systemd.user.timers.nixos-update-notifier = {
    description = "Daily NixOS update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Ensure libnotify is available system-wide
  environment.systemPackages = with pkgs; [
    libnotify
  ];
}
