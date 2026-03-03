_: {
  programs.git = {
    enable = true;

    settings = {
      user.name = "Mitchel Kuijpers";
      user.email = "mitchelkuijpers@gmail.com";
      push.autoSetupRemote = true;
    };

    signing = {
      key = "99A25F98085085A9";
      signByDefault = true;
    };

    ignores = [
      ".DS_Store"
      ".lsp/"
      ".sidecar/"
    ];
  };
}
