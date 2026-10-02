# macOS-only session environment, split out of modules/common/env.nix so the
# shared module stays usable for Linux agent VMs.
{
  config,
  lib,
  ...
}: {
  home.sessionVariables = {
    CONNECT__BASEURL = "https://mitchel.eu.ngrok.io";
    KUBECONFIG = "${config.xdg.dataHome}/.kube/acloud_avisi-solution-studio-6oct_playhouses_playhouse-mitchel_47973c8f";
  };

  # mkBefore preserves the historical PATH order (homebrew ahead of pnpm).
  home.sessionPath = lib.mkBefore [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}
