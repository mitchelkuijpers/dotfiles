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
      inherit (pkgs.importNpmLock) npmConfigHook;

      # Keep builds deterministic and avoid lifecycle scripts reaching out to the network.
      npmInstallFlags = ["--ignore-scripts"];
      dontNpmBuild = true;
    };

  pinnedNpmCliDefinitions = builtins.fromJSON (
    builtins.readFile ../../assets/npm-locks/pinned-packages.json
  );

  pinnedNpmCliPackages =
    builtins.mapAttrs (
      _: cfg:
        mkPinnedNpmCli {
          inherit (cfg) pname version url hash;
          packageFile = ../../assets/npm-locks + "/${cfg.lockBaseName}.package.json";
          lockFile = ../../assets/npm-locks + "/${cfg.lockBaseName}.package-lock.json";
        }
    )
    pinnedNpmCliDefinitions;
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

      # Docker
      docker
      docker-credential-helpers
    ])
    # Install every pinned npm CLI declared in assets/npm-locks/pinned-packages.json.
    ++ builtins.attrValues pinnedNpmCliPackages
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
