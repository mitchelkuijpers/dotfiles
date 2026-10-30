# macOS-only session environment, split out of modules/common/env.nix so the
# shared module stays usable for Linux agent VMs.
{
  config,
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    CONNECT__BASEURL = "https://mitchel.eu.ngrok.io";
    KUBECONFIG = "${config.xdg.dataHome}/.kube/acloud_avisi-solution-studio-6oct_playhouses_playhouse-mitchel_47973c8f";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  # herdr-core starts interactive tabs using the SHELL it inherits from the
  # GUI session; Herdr's terminal.default_shell setting does not affect it.
  home.activation.herdrCoreShell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    /bin/launchctl setenv SHELL ${pkgs.fish}/bin/fish
  '';

  # mkBefore preserves the historical PATH order (homebrew ahead of pnpm).
  home.sessionPath = lib.mkBefore [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}
