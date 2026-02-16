 
{ pkgs, ... }:

{

  # Fish shell - https://wiki.nixos.org/wiki/Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
  };

  users.extraUsers.chaton = {
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fzf
    fishPlugins.grc
    grc
  
    # Use 3rd-party fish plugins manually packaged.
    #(pkgs.callPackage ../fish-colored-man.nix {buildFishPlugin = pkgs.fishPlugins.buildFishPlugin; } )
  ];
}