{ pkgs, inputs, self, ... }:

{
  # Disable the stable niri module
  disabledModules = [ "programs/wayland/niri.nix" ];

  imports = [
    # Import the niri module from unstable
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/niri.nix"
    inputs.nirinit.nixosModules.nirinit
  ];

  # Enable niri compositor
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    # Portals
    gnome-keyring

    # Application launcher
    fuzzel

    # Screenshot tools
    grim
    slurp
    swappy # Screenshot editor

    # Media control
    playerctl # Media player controller
    pavucontrol # PulseAudio volume control

    # Multi-display management
    wdisplays # GUI for display configuration

    # File management
    nautilus # GTK4/libadwaita, integrates with DMS dynamic theming
    #gvfs # Virtual filesystem (for network shares, etc.)
    yazi # TUI file manager (Rust, image previews in Ghostty)

    # Image viewer
    imv # Wayland image viewer

    # PDF viewer
    zathura

    # GTK themes
    papirus-icon-theme
    adwaita-icon-theme
    gnome-themes-extra

    # Network management GUI
    networkmanagerapplet
  ];

  # Session variables for Niri
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    NIXOS_OZONE_WL = "1";
  };

  environment.variables = {
    # GTK 4.20 stopped handling dead keys and Compose on its own on Wayland. To make them work, either run an IME like IBus or Fcitx5, or set the GTK_IM_MODULE=simple environment variable.
    GTK_IM_MODULE = "simple";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # GTK theme configuration for consistent appearance
  programs.dconf.enable = true;

  # Enable GVFS for network shares
  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true; # secret service

  # Nirinit configuration - https://github.com/amaanq/nirinit
  services.nirinit.enable = true;
  users.users.chaton.maid = {
    # Niri declarative config imported from current machine setup.
    file.xdg_config."niri/config.kdl".source = "${self}/desktop/niri/config.kdl";
    file.xdg_config."niri/binds.kdl".source = "${self}/desktop/niri/binds.kdl";
    file.xdg_config."niri/dms-custom.kdl".source = "${self}/desktop/niri/dms-custom.kdl";

    file.xdg_config."nirinit/config.toml".source = "${self}/desktop/niri/nirinit/config.toml";
  };

  # Limit free buffer pool in Wayland compositors
  # https://github.com/NVIDIA/egl-wayland/issues/126#issuecomment-2379945259
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = ''
    {
      "rules": [
        {
          "pattern": {
            "feature": "procname",
            "matches": "niri"
          },
          "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
      ],
      "profiles": [
        {
          "name": "Limit Free Buffer Pool On Wayland Compositors",
          "settings": [
            {
              "key": "GLVidHeapReuseRatio",
              "value": 0
            }
          ]
        }
      ]
    }
  '';
}
