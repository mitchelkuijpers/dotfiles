_: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraConfig = ''
      [keys.normal]
      Cmd-g = [
          ":write-all",
          ":insert-output lazygit >/dev/tty",
          ":redraw",
          ":reload-all"
      ]
    '';
    languages = {
      language-server.kotlin-lsp = {
        command = "kotlin-lsp";
        args = [];
      };
      language = [{
        name = "kotlin";
        language-servers = ["kotlin-lsp"];
      }];
    };
  };
}
