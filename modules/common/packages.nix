{
  pkgs,
  inputs,
  ...
}: let
  llmAgentsPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    tuicr
    rtk
    agent-browser
    codex
    codex-acp
  ];
in {
  home.packages =
    (with pkgs; [
      cmake
      coreutils
      deno
      fd
      gh
      git-crypt
      gnused
      gnutar
      go
      jq
      mkcert
      neovim
      ripgrep
      sd
      shellcheck
      tmuxinator
      zellij
      tree
      uv
      wget
      yq
      zig
      mise
      terraform
      terraform-ls
      gnugrep
      terminal-notifier
      skopeo
      fnm
      helix
      devbox

      # Docker
      docker
      docker-credential-helpers
    ])
    # AI coding agents packaged outside nixpkgs.
    ++ llmAgentsPackages
    ++ (with pkgs; [
      # Node
      yarn
      pnpm
      nodejs_24
      bun

      # Clojure
      clojure
      clojure-lsp
      babashka
      bbin
      clj-kondo
      cljfmt
      polylith

      # Java (LTS)
      jdk21
      maven
    ]);
}
