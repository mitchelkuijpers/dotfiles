-- Rex configuration — tmux-style key bindings with Ctrl+A as the prefix.
--
-- Mirrors ~/.config/tmux/tmux.conf (prefix C-a) as closely as Rex allows.
-- Rex calls tmux windows "tabs" and tmux panes "panes".
--
-- Keys are matched on the character they type, so shifted symbols are written
-- the way Rex wants them: "shift+5" for %, "shift+\\" for |, "shift+'" for ".
--
-- Reload with `rex config reload` (or prefix r). Reference:
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts

local PREFIX = "ctrl+a"

local function bind(keys, action, args)
  rex.bind(PREFIX .. ">" .. keys, action, args)
end

-- Send the prefix itself to the terminal (tmux: bind C-a send-prefix).
-- Once a key starts a sequence it no longer reaches the terminal, so shells
-- that use Ctrl+A (beginning of line) need this.
bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Browse a snapshot of this pane's scrollback in a temporary floating editor.
-- Run capture in the viewer's shell so large histories never pass through Lua.
rex.action {
  name = "scrollback_nvim",
  title = "Open Scrollback in Neovim",
  run = function(ctx)
    if not ctx.session_id or not ctx.block_id then
      error("Focus a terminal pane before opening its scrollback", 0)
    end

    local source, err = rex.session.describe_block { block_id = ctx.block_id }
    if not source then error(err, 0) end
    if source.block.creator_name ~= "com.superlogical.terminal" then
      error("Scrollback is only available for terminal panes", 0)
    end

    local viewer
    viewer, err = rex.session.new_layer {
      window_id = source.block.window_id,
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = {
        block = {
          flavor = "com.superlogical.terminal.shell",
          label = "Scrollback",
          options = {
            command = {
              "sh", "-c", [[
set -eu
# Rex's server may have started before the shell added Home Manager's PATH.
export PATH="$HOME/.nix-profile/bin:$PATH"
scrollback_file=$(mktemp "${TMPDIR:-/tmp}/rex-scrollback.XXXXXX")
trap 'rm -f "$scrollback_file"' EXIT
trap 'exit 1' HUP INT TERM
rex capture -s "$1" -b "$2" --trim --unwrap > "$scrollback_file"
nvim -n -i NONE --cmd 'set nomodeline' --cmd 'let g:clipboard = "osc52"' \
  -c 'set clipboard=unnamedplus' \
  -c 'setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile noundofile' \
  -c 'normal! G' -- "$scrollback_file"
]],
              "rex-scrollback", ctx.session_id, ctx.block_id,
            },
            exit = { on_completion = true },
          },
        },
      },
    }
    if not viewer then error(err, 0) end
    return viewer
  end,
}
bind("[", "scrollback_nvim")

-- Tabs — the closest equivalent to tmux windows.
bind("c", "client.tab.new")
bind(",", "client.tab.rename")
bind("n", "client.tab.next")
-- tmux.conf binds p to choose-buffer, which overrides previous-window.
-- Rex has no buffer list, so p pastes the clipboard instead.
bind("p", "pane.paste")
bind("]", "pane.paste")
bind("shift+7", "client.tab.close") -- & kill-window
-- choose-tree has no Rex equivalent; the command palette is the nearest.
bind("w", "client.palette.toggle")

-- Select a tab by number. tmux counts from 0, Rex tabs count from 1.
for i = 1, 9 do
  bind(tostring(i), "client.tab.goto", { index = i })
end
bind("0", "client.tab.goto", { index = 10 })

-- Select panes (vim-style, as in tmux.conf).
bind("h", "pane.focus.left")
bind("j", "pane.focus.down")
bind("k", "pane.focus.up")
bind("l", "pane.focus.right")

-- Select panes with the arrow keys (tmux default).
bind("left", "pane.focus.left")
bind("down", "pane.focus.down")
bind("up", "pane.focus.up")
bind("right", "pane.focus.right")

bind("o", "pane.focus_next") -- o select-pane -t :.+
bind(";", "pane.focus_previous") -- ; last-pane (previous pane in order)

-- Resize panes. tmux.conf resizes by 5 cells; Rex resizes by percentage.
bind("shift+h", "pane.resize", { direction = "left", amount = 5 })
bind("shift+j", "pane.resize", { direction = "down", amount = 5 })
bind("shift+k", "pane.resize", { direction = "up", amount = 5 })
bind("shift+l", "pane.resize", { direction = "right", amount = 5 })
bind("alt+left", "pane.resize", { direction = "left", amount = 5 })
bind("alt+down", "pane.resize", { direction = "down", amount = 5 })
bind("alt+up", "pane.resize", { direction = "up", amount = 5 })
bind("alt+right", "pane.resize", { direction = "right", amount = 5 })

-- Split panes (- and | from tmux.conf; % and " are the tmux defaults).
bind("-", "pane.split", { direction = "down" })
bind("shift+\\", "pane.split", { direction = "right" })
bind("shift+'", "pane.split", { direction = "down" })
bind("shift+5", "pane.split", { direction = "right" })

bind("z", "pane.zoom")
bind("x", "pane.close") -- x kill-pane
bind("shift+1", "pane.move_to_new_tab") -- ! break-pane
bind("space", "pane.balance") -- space next-layout: balance is the nearest match

-- Sessions.
bind("s", "session.switch") -- s choose-tree -s
bind("shift+4", "session.rename") -- $ rename-session
bind("shift+9", "session.next") -- ) switch-client -n
bind("shift+0", "session.previous") -- ( switch-client -p

-- Config and command palette.
bind("r", "client.config.reload") -- r source-file ~/.config/tmux/tmux.conf
bind("shift+/", "client.palette.toggle") -- ? list-keys
bind("shift+;", "client.palette.toggle") -- : command-prompt

-- No Rex equivalent, so left unbound:
--   prefix = / # choose-buffer  (pastes from the clipboard instead)
--   prefix d     detach-client  (close the window or hide the app instead)
--   prefix q     display-panes
--   prefix t     clock-mode
