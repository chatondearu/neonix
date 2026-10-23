{self, ...}: {
  users.users.chaton.maid = {
    file.xdg_config."fuzzel/fuzzel.ini".source = "${self}/desktop/fuzzel/fuzzel.ini";
  };
}
