{pkgs, ...}: {
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
}
