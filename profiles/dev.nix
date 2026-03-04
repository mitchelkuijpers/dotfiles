_: {
  imports = [
    ./base.nix
    ../modules/common/packages.nix
    ../modules/services/colima.nix

    ../modules/programs/mise.nix
    ../modules/programs/direnv.nix
    ../modules/programs/fzf.nix
    ../modules/programs/starship.nix
  ];
}
