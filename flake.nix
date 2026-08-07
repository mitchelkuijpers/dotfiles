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
  in {
    # Makes `nix run .` launch the home-manager CLI
    packages.${system}.default = home-manager.packages.${system}.default;

    homeConfigurations.mitkuijp = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit inputs;};
      modules = [./hosts/mitkuijp-macbook/home.nix];
    };
  };
}
