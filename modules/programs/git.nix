{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      user.name = "Mitchel Kuijpers";
      user.email = "mitchel.kuijpers@avisi.nl";
      push.autoSetupRemote = true;
      # SSH signing is Mac-only: agent VMs deliberately get no personal keys.
      gpg.format = lib.mkIf pkgs.stdenv.isDarwin "ssh";
    };

    signing = lib.mkIf pkgs.stdenv.isDarwin {
      key = "${config.home.homeDirectory}/.ssh/avisi.pub";
      signByDefault = true;
    };

    ignores = [
      ".DS_Store"
      ".lsp/"
      ".sidecar/"
    ];
  };
}
