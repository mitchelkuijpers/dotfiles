_: {
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "fish";
      # Set to locked if I get into issues with shortcuts
      default_mode = "normal";
      theme = "catppuccin-macchiato";
      simplified_ui = true;
      show_startup_tips = false;
    };
  };
}
