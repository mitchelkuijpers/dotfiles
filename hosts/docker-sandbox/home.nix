{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.rex.homeManagerModules.default
    ../../modules/programs/fish-shared.nix
    ../../modules/programs/fzf.nix
    ../../modules/programs/pi-shared.nix
    ../../modules/programs/rex.nix
    ../../modules/programs/starship.nix
  ];

  programs.rex = {
    enable = true;
    sshGuard = false;
  };

  manual.manpages.enable = false;
  systemd.user.enable = false;

  home = {
    username = "agent";
    homeDirectory = "/home/agent";
    stateVersion = "24.11";
    packages = [
      pkgs.neovim
      pkgs.fd
      pkgs.ripgrep
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk
    ];
  };
}
