{
  pkgs,
  inputs,
  ...
}: let
  llmAgentsPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    tuicr
    codex
    opencode
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

      #Fish
      fishPlugins.bass
      fishPlugins.z

      # Docker
      docker
      docker-credential-helpers

      # AI
      ansible

      #Avisi Cloud
      kubernetes-helm

      # Entrance
      kubectl
      awscli2
      freelens-bin
      k9s
    ])
    # AI coding agents packaged outside nixpkgs.
    ++ llmAgentsPackages
    ++ (with pkgs; [
      qemu

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

      # Kotlin
      kotlin

      # Solution Studio
      ffmpeg
      whisper-cpp
    ]);
}
