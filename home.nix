{ pkgs, ... }:
{
  home.username = "mitkuijp";
  home.homeDirectory = "/Users/mitkuijp";

  # Set this once when you start, then don't bump casually.
  home.stateVersion = "24.11";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    LANG = "en_US.UTF-8";
    CONNECT__BASEURL = "https://mitchel.eu.ngrok.io";
  };

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;

    settings = {
      user.name = "Mitchel Kuijpers";
      user.email = "mitchelkuijpers@gmail.com";
      push.autoSetupRemote = true;
    };

    signing = {
      key = "99A25F98085085A9";
      signByDefault = true;
    };

    ignores = [
      ".DS_Store"
      ".lsp/"
      ".sidecar/"
    ];
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings

      # Keep Nix profile paths in front so Nix-installed tools win over system ones.
      fish_add_path --prepend --move ~/.nix-profile/bin /etc/profiles/per-user/$USER/bin
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    cmake
    coreutils
    deno
    fd
    gh
    git-crypt
    gnused
    gnutar
    go
    jq
    mkcert
    neovim
    ripgrep
    sd
    shellcheck
    tmuxinator
    tree
    uv
    wget
    yq
    zig
  ];
}
