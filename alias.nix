{ ... }:

{
  environment = {
    shellAliases = {
      neo-monado = "systemctl --user start monado.service";
    };
  };
}