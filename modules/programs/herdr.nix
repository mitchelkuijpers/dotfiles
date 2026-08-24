{
  inputs,
  pkgs,
  ...
}: {
  programs.herdr = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;

    # Configuration written to $XDG_CONFIG_HOME/herdr/config.toml.
    # Full reference: https://herdr.dev/docs/configuration/
    # Defaults are commented out — uncomment and change any value to override.
    settings = {
      # Show first-run notification setup on startup.
      # Missing also shows onboarding; set false after you've chosen.
      onboarding = false;

      theme = {
        # Built-in themes: catppuccin, terminal, tokyo-night, dracula, nord,
        #                  gruvbox, one-dark, solarized, kanagawa, rose-pine,
        #                  vesper
        name = "catppuccin";

        # Follow host terminal light/dark appearance and switch Herdr UI themes.
        # auto_switch = false;
        # dark_name = "catppuccin";
        # light_name = "catppuccin-latte";

        # Override individual color tokens on top of the base theme.
        # Accepts: hex (#rrggbb), named colors, rgb(r,g,b), or panel_bg = "reset"
        # custom = {
        #   panel_bg = "reset";
        #   accent = "#f5c2e7";
        #   red = "#ff6188";
        #   green = "#a6e3a1";
        # };
      };

      terminal = {
        # Executable used for new interactive panes.
        # Empty means $SHELL, then /bin/sh.
        default_shell = "fish";

        # Startup mode for new interactive pane shells: "auto", "login", or "non_login".
        # "auto" uses login shells on macOS and keeps the current behavior elsewhere.
        # shell_mode = "auto";

        # CWD policy for new panes, tabs, and workspaces when no explicit --cwd is provided.
        # Use "follow" to inherit the source pane/workspace, "home" for $HOME,
        # "current" for Herdr's process directory, or a fixed path such as "~/Projects".
        new_cwd = "follow";
      };

      update = {
        # Update channel used by background version checks and `herdr update`.
        # Use "stable" for normal releases or "preview" for opt-in preview builds.
        # channel = "stable";

        # Check herdr.dev for new Herdr versions in the background.
        version_check = false;

        # Check herdr.dev for remote agent-detection manifest updates in the background.
        # manifest_check = true;
      };

      keys = {
        # Prefix key to enter prefix mode (default: "ctrl+b")
        prefix = "ctrl+a";

        # Prefix-mode actions
        # help = "prefix+?";
        # settings = "prefix+s";
        # detach = "prefix+q";
        # reload_config = "prefix+shift+r";
        # open_notification_target = "prefix+o";
        # workspace_picker = "prefix+w";
        # goto = "prefix+g";
        # new_workspace = "prefix+shift+n";
        # new_worktree = "prefix+shift+g";
        # open_worktree = "";       # optional, unset by default
        # remove_worktree = "";     # optional, unset by default; opens confirmation
        # rename_workspace = "prefix+shift+w";
        # close_workspace = "prefix+shift+d";
        # previous_workspace = "";  # optional, unset by default
        # next_workspace = "";      # optional, unset by default
        # previous_agent = "";      # optional, unset by default
        # next_agent = "";          # optional, unset by default
        # focus_agent = "";         # optional indexed binding, e.g. "prefix+alt+1..9"
        # remote_image_paste = "ctrl+v";  # only active in herdr --remote
        # new_tab = "prefix+c";
        # rename_tab = "prefix+shift+t";
        # previous_tab = "prefix+p";
        # next_tab = "prefix+n";
        # switch_tab = "prefix+1..9";
        # switch_workspace = "";    # optional indexed binding, e.g. "prefix+shift+1..9"
        # close_tab = "prefix+shift+x";
        # rename_pane = "prefix+shift+p";
        # edit_scrollback = "prefix+e";
        # focus_pane_left = "prefix+h";
        # focus_pane_down = "prefix+j";
        # focus_pane_up = "prefix+k";
        # focus_pane_right = "prefix+l";
        # cycle_pane_next = "prefix+tab";
        # cycle_pane_previous = "prefix+shift+tab";
        # last_pane = "";           # optional, unset by default
        # split_vertical = "prefix+v";
        # split_horizontal = "prefix+minus";
        # close_pane = "prefix+x";
        # zoom = "prefix+z";        # legacy alias: fullscreen
        # resize_mode = "prefix+r";
        # toggle_sidebar = "prefix+b";

        # Navigate-mode movement (active while navigate mode is open).
        navigate_workspace_up = "k";
        navigate_workspace_down = "j";
        # navigate_pane_left = "h";
        # navigate_pane_down = "j";
        # navigate_pane_up = "k";
        # navigate_pane_right = "l";

        # Custom commands use the same binding syntax.
        # type = "shell" runs detached in the background.
        # type = "pane" opens a temporary pane and closes it when the command exits.
        command = [
          {
            key = "cmd+r";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
          }
        ];

        # Legacy indexed shortcut config (still parsed for compatibility).
        # Prefer switch_tab, switch_workspace, and focus_agent for new configs.
        # indexed = {
        #   tabs = "";       # e.g. "ctrl" makes ctrl+1..9 switch tabs directly
        #   workspaces = ""; # e.g. "ctrl+shift" makes ctrl+shift+1..9 switch workspaces directly
        #   agents = "";     # e.g. "alt" makes alt+1..9 focus agent rows directly
        # };
      };

      # worktrees.directory = "~/.herdr/worktrees";

      ui = {
        # Sidebar width (auto-scaled based on workspace names, this sets the default)
        # sidebar_width = 26;
        # sidebar_min_width = 18;   # minimum when expanded
        # sidebar_max_width = 36;   # maximum when expanded
        # sidebar_collapsed_mode = "compact";  # "compact" or "hidden"

        # Terminal width at or below which Herdr uses the mobile single-column layout.
        # mobile_width_threshold = 64;

        # mouse_capture = true;     # set false to let terminal handle clicks
        # host_cursor = "auto";     # "auto", "native", or "drawn"
        # right_click_passthrough_modifier = "";
        # redraw_on_focus_gained = true;
        # mouse_scroll_lines = 3;
        # confirm_close = true;
        # prompt_new_tab_name = true;
        # pane_borders = true;
        # pane_gaps = true;
        # show_agent_labels_on_pane_borders = false;
        # hide_tab_bar_when_single_tab = false;
        # agent_panel_sort = "spaces";  # "spaces" or "priority"
        # accent = "cyan";              # hex, named color, or rgb(r,g,b)

        toast = {
          # off = disable, herdr = in-app, terminal = outer terminal, system = OS service
          # delivery = "off";
          # delay_seconds = 1;
          # herdr.position = "bottom-right";
          # clipboard = {
          #   enabled = true;
          #   position = "bottom-center";
          # };
        };

        sound = {
          # enabled = true;
          # path = "sounds/notification.mp3";       # one mp3 for all notifications
          # done_path = "sounds/done.mp3";          # overrides finished notifications
          # request_path = "sounds/request.mp3";   # overrides needs-attention notifications
          # Per-agent overrides: default | on | off (droid is muted by default)
          # agents.droid = "off";
        };
      };

      session = {
        # Resume supported AI-agent panes into their native conversation sessions after
        # a Herdr server restart. Requires official integrations that report session refs.
        # resume_agents_on_restore = true;
      };

      remote = {
        # Whether herdr manages the ssh config used for `herdr --remote`.
        # manage_ssh_config = true;
      };

      experimental = {
        # allow_nested = false;
        # kitty_graphics = false;
        # pane_history = false;
        # switch_ascii_input_source_in_prefix = false;
        # reveal_hidden_cursor_for_cjk_ime = false;
        # cjk_ime_agents = [];  # pi, claude, codex, gemini, cursor, devin, cline, opencode, ...
        # cjk_ime_cursor_shape = "steady_block";  # block, underline, bar (+ steady_ variants)
      };

      advanced = {
        # Maximum scrollback buffer size in bytes retained per pane terminal.
        # scrollback_limit_bytes = 10000000;
      };
    };
  };
}
