{
  description = "Home Manager config for mitkuijp";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
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
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "terraform"
        ];
    };
  in {
    # Makes `nix run .` launch the pinned home-manager CLI
    packages.${system}.default = home-manager.packages.${system}.default;

    homeConfigurations.mitkuijp = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs;
      };
      modules = [./hosts/mitkuijp-macbook/home.nix];
    };
  };
}
