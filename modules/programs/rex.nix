{
  # Rex is a macOS desktop app, so this module is only imported from the dev
  # profile. It links a tmux-flavoured init.lua (Ctrl+A prefix) into place.
  xdg.configFile."rex/init.lua".source = ../../assets/rex/init.lua;
}
