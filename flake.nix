{
  description = "Home Manager config for mitkuijp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
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
      modules = [./hosts/mitkuijp-macbook/home.nix];
    };
  };
}
