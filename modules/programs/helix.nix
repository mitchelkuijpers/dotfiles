_: {
  programs.helix = {
    enable = true;
    defaultEditor = false;
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
      language-server = {
        kotlin-lsp = {
          command = "kotlin-lsp";
          args = [];
        };
        tailwindcss-ls = {
          commmand = "tailwindcss-language-server";
          args = ["--stdio"];
        };
      };
      language = [
        {
          name = "kotlin";
          language-servers = ["kotlin-lsp"];
        }
        {
          name = "css";
          language-servers = ["vscode-css-language-server" "tailwindcss-ls"];
        }
        {
          name = "jsx";
          language-servers = ["typescript-language-server" "tailwindcss-ls"];
        }
        {
          name = "tsx";
          language-servers = ["typescript-language-server" "tailwindcss-ls"];
        }
      ];
    };
  };
}
