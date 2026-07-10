{config, ...}: let
  pnpmHome = "${config.xdg.dataHome}/pnpm";
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    CONNECT__BASEURL = "https://mitchel.eu.ngrok.io";
    PNPM_HOME = pnpmHome;
    KUBECONFIG = "${config.xdg.dataHome}/.kube/acloud_avisi-solution-studio-6oct_playhouses_playhouse-mitchel_47973c8f";
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "${pnpmHome}/bin"
  ];
}
