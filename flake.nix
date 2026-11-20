{
  description = "Home Manager config for mitkuijp";

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    # Systems we evaluate for: the Mac, and Linux agent VMs on both arches
    # (see plans/agent-vms.md; exe.dev VMs can be x86_64 or aarch64).
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];

    # Temporary git pin: 2.56.1 carries the Nov 2026 security fixes
    # (CVE-2026-111760/-113408/-114466/-114467/-114469/-105437). nixpkgs-unstable
    # still ships 2.56.0; drop this overlay once it moves to >= 2.56.1.
    gitSecurityFix = _final: prev: {
      git = prev.git.overrideAttrs (old: {
        version = "2.56.1";
        src = prev.fetchurl {
          url = "https://www.kernel.org/pub/software/scm/git/git-2.56.1.tar.xz";
          hash = "sha256-8LC/iSZLm9LhxkA2PnUpZDmJ2nYoFgBHPFB0XNNKYH8=";
        };
        # Upstream as of 2.56.1, so the patch no longer applies.
        patches =
          builtins.filter (
            p: !(prev.lib.hasInfix "darwin-unicode-filename-fix" (p.name or (toString p)))
          )
          old.patches;
      });
    };

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [gitSecurityFix];
      };

    mkHome = system: hostModule:
      home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = {inherit inputs;};
        modules = [hostModule];
      };

    # Home Manager entry baked into the local agent sandbox OCI image
    # (microsandbox.dev) — see images/agent-image.nix.
    msbHome = mkHome "aarch64-linux" ./hosts/msb/home.nix;
  in {
    formatter = nixpkgs.lib.genAttrs systems (system: (mkPkgs system).alejandra);

    # Makes `nix run .` launch the home-manager CLI, on any supported system
    # (agent VMs bootstrap via `nix run . -- switch --flake .#exedev-arm`),
    # plus the local agent sandbox OCI image (microsandbox.dev, arm-only —
    # MSB on the Mac boots aarch64-linux guests).
    packages = let
      base = nixpkgs.lib.genAttrs systems (system: {
        default = home-manager.packages.${system}.default;
      });
    in
      base
      // {
        aarch64-linux =
          base.aarch64-linux
          // {
            agent-image = import ./images/agent-image.nix {
              pkgs = mkPkgs "aarch64-linux";
              inherit (msbHome) activationPackage;
            };
          };
      };

    homeConfigurations = {
      mitkuijp = mkHome "aarch64-darwin" ./hosts/mitkuijp-macbook/home.nix;

      # Linux agent VMs (exe.dev login user `exedev`); pick by `uname -m`.
      exedev = mkHome "x86_64-linux" ./hosts/exedev/home.nix;
      exedev-arm = mkHome "aarch64-linux" ./hosts/exedev/home.nix;

      # shellbox.dev boxes: Azure x86_64 Ubuntu, ssh in as root
      # (ssh <boxname>@shellbox.dev).
      shellbox = mkHome "x86_64-linux" ./hosts/shellbox/home.nix;
    };

    # Local agent sandbox (microsandbox.dev) — not a host you deploy to; the
    # activation package is baked into packages.aarch64-linux.agent-image.
    homeConfigurations.msb = msbHome;
  };
}
