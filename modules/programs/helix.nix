_: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
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
