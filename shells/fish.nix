{ pkgs, ... }:

{
  # Fish shell for user chaton - https://wiki.nixos.org/wiki/Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
  };

  # Override default shell for chaton
  users.extraUsers.chaton = {
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    # Fish plugins
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc

    # Plugin dependencies
    fzf
    grc
    jq # Required by fishPlugins.done for window focus detection
  ];
}
