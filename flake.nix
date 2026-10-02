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
    maki.url = "github:tontinton/maki";

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
  in {
    # Makes `nix run .` launch the home-manager CLI, on any supported system
    # (agent VMs bootstrap via `nix run . -- switch --flake .#exedev-arm`).
    packages = nixpkgs.lib.genAttrs systems (system: {
      default = home-manager.packages.${system}.default;
    });

    homeConfigurations = {
      mitkuijp = mkHome "aarch64-darwin" ./hosts/mitkuijp-macbook/home.nix;

      # Linux agent VMs (exe.dev login user `exedev`); pick by `uname -m`.
      exedev = mkHome "x86_64-linux" ./hosts/exedev/home.nix;
      exedev-arm = mkHome "aarch64-linux" ./hosts/exedev/home.nix;

      # shellbox.dev boxes: Azure x86_64 Ubuntu, ssh in as root
      # (ssh <boxname>@shellbox.dev).
      shellbox = mkHome "x86_64-linux" ./hosts/shellbox/home.nix;
    };
  };
}
