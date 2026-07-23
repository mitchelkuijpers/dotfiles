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
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/7a1a64774a5fd0b0cd39ac95d0e170ace8b266a0";
    nixpkgs-mise.url = "github:NixOS/nixpkgs/e839d2252707ca85e2c903285962b02b8c1a89f0";
    llm-agents.url = "github:numtide/llm-agents.nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-pinned,
    home-manager,
    ...
  }: let
    system = "aarch64-darwin";

    mkPkgs = src:
      import src {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (src.lib.getName pkg) [
            "terraform"
          ];
      };

    pkgs = mkPkgs nixpkgs;
    pkgsPinned = mkPkgs nixpkgs-pinned;
  in {
    # Makes `nix run .` launch the pinned home-manager CLI
    packages.${system}.default = home-manager.packages.${system}.default;

    homeConfigurations.mitkuijp = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs pkgsPinned;
      };
      modules = [./hosts/mitkuijp-macbook/home.nix];
    };
  };
}
