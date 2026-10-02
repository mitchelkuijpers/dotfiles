{
  pkgs,
  lib,
  inputs,
  ...
}: let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  llmAgentsPackages = with llmAgents; [
    tuicr
    hunk
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
  # Workstation/work extras that agent VMs deliberately skip, both to keep
  # bootstraps lean (several GiB of downloads) and because they're useless
  # there:
  #   mkcert/bws        - secrets + local TLS are Mac-side
  #   kubectl/k9s/helm  - no kubeconfig on VMs (Decision 3)
  #   qemu              - shellbox/exe.dev don't allow nested virt
  #   terraform/ansible - work infra tooling
  #   jdk/clojure/etc   - Solution Studio languages
  #   ffmpeg/whisper    - Solution Studio media pipeline
  workstationExtras = with pkgs; [
    mkcert
    zig
    terraform
    terraform-ls

    # Bitwarden secrets manager CLI
    bws

    # AI
    ansible

    # Avisi Cloud
    kubernetes-helm

    # Entrance
    kubectl
    awscli2
    k9s

    qemu

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
  ];
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
      neovim
      ripgrep
      sd
      shellcheck
      tmuxinator
      tree
      uv
      wget
      yq
      gnugrep
      skopeo

      #Fish
      fishPlugins.bass
      fishPlugins.z

      # Docker
      docker
      docker-credential-helpers

      glab
    ])
    # macOS-only tools (nono sandbox wrappers reference ~/.config/nono
    # profiles that only exist on the Mac).
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [nonoPi nonoOpencode nonoOmp]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
      terminal-notifier
      freelens-bin
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin workstationExtras
    # codex is unused and every linux build compiles it from source
    # (librusty_v8 + rust tree; numtide cache misses) — Mac only.
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [llmAgents.codex]
    ++ llmAgentsPackages
    ++ (with pkgs; [
      # Node
      pnpm
      nodejs_24
      bun
    ]);
}
