{config, ...}: {
  programs.git = {
    enable = true;

    settings = {
      user.name = "Mitchel Kuijpers";
      user.email = "mitchel.kuijpers@avisi.nl";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
    };

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    ignores = [
      ".DS_Store"
      ".lsp/"
      ".sidecar/"
    ];
  };
}
