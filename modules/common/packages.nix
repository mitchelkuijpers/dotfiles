{
  pkgs,
  lib,
  inputs,
  ...
}: let
  llmAgentsPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    tuicr
    hunk
    codex
    opencode2
    terminal-browser
  ];

  nonoPi = pkgs.writeShellScriptBin "nono-pi" ''
    exec env HERDR_AGENT=pi nono run --silent --profile pi --allow-cwd -- pi "$@"
  '';

  nonoOpencode = pkgs.writeShellScriptBin "nono-opencode" ''
    exec env SHELL=/bin/bash HERDR_AGENT=opencode nono run --silent --profile opencode --allow-cwd -- opencode2 --auto "$@"
  '';

  nonoOmp = pkgs.writeShellScriptBin "nono-omp" ''
    exec env HERDR_AGENT=omp nono run --silent --profile omp-local --allow-cwd -- omp --approval-mode=yolo "$@"
  '';
in {
  home.packages =
    (with pkgs; [
      cmake
      coreutils
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
      tree
      uv
      wget
      yq
      zig
      terraform
      terraform-ls
      gnugrep
      skopeo

      # Bitwarden secrets manager CLI
      bws

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

      glab

      # Entrance
      kubectl
      awscli2
      k9s
    ])
    # macOS-only tools (nono sandbox wrappers reference ~/.config/nono
    # profiles that only exist on the Mac).
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [nonoPi nonoOpencode nonoOmp]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
      terminal-notifier
      freelens-bin
    ])
    ++ llmAgentsPackages
    ++ (with pkgs; [
      qemu

      # Node
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
