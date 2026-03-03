{ ... }:
{
  imports = [
    ../../profiles/dev.nix
  ];

  home.username = "mitkuijp";
  home.homeDirectory = "/Users/mitkuijp";

  # Set this once when you start, then don't bump casually.
  home.stateVersion = "24.11";
}
