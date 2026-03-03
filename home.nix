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


  xdg.configFile."tmuxinator" = {
    source = ./tmuxinator;
    recursive = true;
  };

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

  # Keep compatibility for tools/scripts that still expect ~/.tmux.conf.
  home.file.".tmux.conf".text = ''
    source-file ~/.config/tmux/tmux.conf
  '';

  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 30000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      cpu
      battery
      catppuccin
    ];

    extraConfig = ''
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi y send -X copy-selection

      # Switch panes (vim-style)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes
      bind-key H resize-pane -L 5
      bind-key J resize-pane -D 5
      bind-key K resize-pane -U 5
      bind-key L resize-pane -R 5

      bind-key p choose-buffer

      # New panes/windows open in the current directory
      bind c new-window -c "#{pane_current_path}"
      bind - split-window -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded..."

      # Catppuccin
      set -g @catppuccin_flavor "macchiato"
      set -g @catppuccin_window_status_style "basic"

      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -agF status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_uptime}"
      set -agF status-right "#{E:@catppuccin_status_battery}"
    '';
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
