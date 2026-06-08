{config, ...}: let
  pnpmHome = "${config.xdg.dataHome}/.local/share/pnpm";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    CONNECT__BASEURL = "https://mitchel.eu.ngrok.io";
    PNPM_HOME = pnpmHome;
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    pnpmHome
  ];
}
