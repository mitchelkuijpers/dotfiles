{
  pkgs,
  lib,
  inputs,
  ...
}: let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  # Installed everywhere, including linux agent VMs. opencode2 is wanted on
  # VMs (it substitutes fine); hunk is small and useful there too.
  llmAgentsPackages = [llmAgents.hunk llmAgents.opencode2];
  # Kept on the Mac: codex builds a large Rust project on Linux, while
  # tuicr and terminal-browser are macOS-only.
  llmAgentsDarwinOnly = with llmAgents; [
    codex
    docker-sbx
    tuicr
    terminal-browser
  ];

  nonoPi = pkgs.writeShellScriptBin "nono-pi" ''
    exec env HERDR_AGENT=pi nono run --silent --profile pi --allow-cwd -- pi "$@"
  '';

  nonoOpencode = pkgs.writeShellScriptBin "nono-opencode" ''
    exec env SHELL=/bin/bash HERDR_AGENT=opencode nono run --silent --profile opencode --allow-cwd -- opencode2 --auto "$@"
  '';

  # Workstation/work extras that agent VMs deliberately skip, both to keep
  # bootstraps lean (several GiB of downloads) and because they're useless
  # there:
  #   mkcert            - local TLS is Mac-side
  #   kubectl/k9s/helm  - no kubeconfig on VMs (Decision 3)
  #   qemu              - shellbox/exe.dev don't allow nested virt
  #   terraform         - work infra tooling
  #   jdk/clojure/etc   - Solution Studio languages
  #   ffmpeg            - Solution Studio media pipeline
  workstationExtras = with pkgs; [
    mkcert
    zig
    terraform
    terraform-ls

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
  ];
in {
  # Node/Go/Python toolchains are managed by mise per-project, not Nix.
  # Keep pnpm available for Pi's npmCommand on both Mac and agent VMs.
  home.packages =
    (with pkgs; [
      coreutils
      fd
      gh
      git-crypt
      gnused
      gnutar
      jq
      neovim
      pnpm
      ripgrep
      sd
      shellcheck
      tmuxinator
      tree
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
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [nonoPi nonoOpencode]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with pkgs; [
      terminal-notifier
      freelens-bin
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin workstationExtras
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin llmAgentsDarwinOnly
    ++ llmAgentsPackages;
}
