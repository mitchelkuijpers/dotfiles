#!/usr/bin/env bash
# Run over SSH on the guest, with the expected commit passed by the controller.
set -euo pipefail

state_dir="$HOME/.local/state/dotfiles-bootstrap"
status=$(cat "$state_dir/status" 2>/dev/null || true)
case "$status" in
  failed) tail -n 35 "$state_dir/setup.log" >&2; exit 1 ;;
  ready) ;;
  *)
    service_state=$(systemctl show exe-setup.service --property=ActiveState --value 2>/dev/null || true)
    if [[ "$service_state" == failed ]]; then
      journalctl -b -u exe-setup.service --no-pager -n 35 >&2 || true
      exit 1
    fi
    if [[ "$status" == running ]]; then
      echo '==> First-boot setup is running. Latest output:'
      tail -n 5 "$state_dir/setup.log" 2>/dev/null || true
    else
      echo "==> SSH is ready. Waiting for the first-boot script (service: ${service_state:-unknown})."
    fi
    exit 75
    ;;
esac

actual_revision=$(git -C "$HOME/dotfiles" rev-parse HEAD)
if [[ "$actual_revision" != "$1" ]]; then
  echo "Expected revision $1, got $actual_revision." >&2
  exit 1
fi
echo "Dotfiles revision: $actual_revision"
# Fish expands the variables in its command.
# shellcheck disable=SC2016
TERM=xterm "$HOME/.nix-profile/bin/fish" --login --interactive --command '
  set -l editor (command -s nvim)
  if contains -- "$editor" "$HOME/.nix-profile/bin/nvim" "/etc/profiles/per-user/$USER/bin/nvim"
    nvim --version
    and nvim --headless -u NONE +q
  else
    echo "Expected a managed Neovim, found: $editor" >&2
    exit 1
  end
' | sed -n '/^NVIM /p'
XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
systemctl --user is-enabled rex.service
systemctl --user is-active rex.service
test -e "/var/lib/systemd/linger/$(id -un)"
rex=("$HOME/.local/bin/rex" --autostart=false)
"${rex[@]}" version | sed -n '1p'
created=$("${rex[@]}" new --keep-open --shell=none --json dotfiles-bootstrap-check -- /bin/true)
session=$(jq -er '.session_id' <<< "$created")
trap '"${rex[@]}" kill "$session" >/dev/null' EXIT
block=$(jq -er '.initial_windows[0].block_ids[0]' <<< "$created")
"${rex[@]}" wait -s "$session" "$block" --for 15s >/dev/null
echo 'Rex smoke command passed.'
