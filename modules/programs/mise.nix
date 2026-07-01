{
  inputs,
  pkgs,
  ...
}: let
  misePkgs = import inputs.nixpkgs-mise {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in {
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    package = misePkgs.mise;
  };
}
