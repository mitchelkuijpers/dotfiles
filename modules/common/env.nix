{config, ...}: let
  pnpmHome = "${config.xdg.dataHome}/pnpm";
in {
  # Cross-platform session environment. macOS-only entries (Homebrew PATH,
  # personal KUBECONFIG/CONNECT__BASEURL) live in hosts/mitkuijp-macbook/env.nix.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    PNPM_HOME = pnpmHome;
  };

  home.sessionPath = [
    "${pnpmHome}/bin"
  ];
}
