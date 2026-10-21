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
    # Keep OMP at least as new as the workstation's existing database without
    # moving Pi and the other agents off the independently pinned input.
    omp-agents = {
      url = "github:numtide/llm-agents.nix/c5beab1cbccf7b09060b16954a6eca15398140c5";
      inputs = {
        nixpkgs.follows = "llm-agents/nixpkgs";
        bun2nix.follows = "llm-agents/bun2nix";
        flake-parts.follows = "llm-agents/flake-parts";
        systems.follows = "llm-agents/systems";
        treefmt-nix.follows = "llm-agents/treefmt-nix";
      };
    };
    maki.url = "github:tontinton/maki";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    # Systems we evaluate for: the Mac, and Linux agent VMs on both arches
    # (see plans/agent-vms.md; exe.dev VMs can be x86_64 or aarch64).
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
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
