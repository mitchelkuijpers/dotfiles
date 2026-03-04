{pkgs, ...}: let
  mkPinnedNpmCli = {
    pname,
    version,
    url,
    hash,
    packageFile,
    lockFile,
  }: let
    src = pkgs.fetchurl {
      inherit url hash;
    };

    package = builtins.fromJSON (builtins.readFile packageFile);
    packageLock = builtins.fromJSON (builtins.readFile lockFile);
  in
    pkgs.buildNpmPackage {
      inherit pname version src;
      sourceRoot = "package";

      npmDeps = pkgs.importNpmLock {
        inherit package packageLock;
      };
      npmConfigHook = pkgs.importNpmLock.npmConfigHook;

      # Keep builds deterministic and avoid lifecycle scripts reaching out to the network.
      npmInstallFlags = ["--ignore-scripts"];
      dontNpmBuild = true;
    };

  piCodingAgent = mkPinnedNpmCli {
    pname = "pi-coding-agent";
    version = "0.55.4";
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-0.55.4.tgz";
    hash = "sha256-GnzPe1QJcFhpLZVlREvgRu/zh3GTXxeK/o58DdQ6QiI=";
    packageFile = ../../assets/npm-locks/pi-coding-agent.package.json;
    lockFile = ../../assets/npm-locks/pi-coding-agent.package-lock.json;
  };

  opencodeAi = mkPinnedNpmCli {
    pname = "opencode-ai";
    version = "1.2.17";
    url = "https://registry.npmjs.org/opencode-ai/-/opencode-ai-1.2.17.tgz";
    hash = "sha256-zwoIZ6ajQY7WOhLa9d9gOgWv3XoKGE81jemkzFY7zoY=";
    packageFile = ../../assets/npm-locks/opencode-ai.package.json;
    lockFile = ../../assets/npm-locks/opencode-ai.package-lock.json;
  };
in {
  home.packages = with pkgs; [
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
    tree
    uv
    wget
    yq
    zig
    codex
    mise
    terraform
    terraform-ls
    gnugrep
    terminal-notifier

    # Docker
    docker

    # AI
    piCodingAgent
    opencodeAi

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
  ];
}
