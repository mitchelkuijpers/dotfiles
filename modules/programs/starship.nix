{pkgsPinned, ...}: {
  programs.starship = {
    enable = true;
    package = pkgsPinned.starship;
    enableFishIntegration = true;
    settings = {
      # add_newline = false;

      # character = {
      #   success_symbol = "[➜](bold green)";
      #   error_symbol = "[➜](bold red)";
      # };

      # package.disabled = true;

      mise.disabled = false;
    };
  };
}
