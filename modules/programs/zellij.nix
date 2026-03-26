_: {
  programs.zellij = {
    enable = true;
    # enableFishIntegration = true;
    settings = {
      default_mode = "locked";
      theme = "catppuccin-macchiato";
      simplified_ui = true;
      show_startup_tips = false;
    };
  };
}
