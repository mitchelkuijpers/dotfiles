#!/usr/bin/env bash
# Run on the controller, typically the Mac. The new VM builds its own profile.
set -euo pipefail

vm=${1:-${VM:-}}
revision=${2:-${REV:-}}
wait_seconds=${VM_WAIT_SECONDS:-1200}
disk=${VM_DISK:-}
if [[ ! "$vm" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ || ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Usage: make vm-new VM=dev-pilot REV=<full published commit SHA>' >&2
  exit 2
fi
if [[ ! "$wait_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo 'VM_WAIT_SECONDS must be a positive integer.' >&2
  exit 2
fi
create_args=(new --name="$vm" --tag=agent)
if [[ -n "$disk" ]]; then
  if [[ ! "$disk" =~ ^[1-9][0-9]*(GB|TB)$ ]]; then
    echo 'VM_DISK must be a size such as 40GB.' >&2
    exit 2
  fi
  create_args+=(--disk="$disk")
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if ! git -C "$script_dir/.." cat-file -e "$revision:scripts/setup-vm.sh" \
  || ! setup_script=$(git -C "$script_dir/.." show "$revision:scripts/exedev-first-boot.sh"); then
  echo 'The selected commit must include the fleet pilot scripts. Fetch or commit the pilot before creating a VM.' >&2
  exit 1
fi
ssh_options=(-o BatchMode=yes -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2)
command -v jq >/dev/null || { echo 'jq is required on the controller.' >&2; exit 1; }
inventory=$(ssh "${ssh_options[@]}" exe.dev ls --json)
if jq -e --arg vm "$vm" '.vms | any(.vm_name == $vm)' <<< "$inventory" >/dev/null; then
  echo "A VM named $vm already exists. Choose a fresh name for its replacement." >&2
  exit 1
fi

echo "==> Creating $vm with tag agent at dotfiles revision $revision"
printf '%s\n' "${setup_script//@DOTFILES_REV@/$revision}" \
  | ssh "${ssh_options[@]}" exe.dev "${create_args[@]}" --setup-script /dev/stdin

if ! dest=$(ssh "${ssh_options[@]}" exe.dev ls --json \
  | jq -er --arg vm "$vm" '.vms[] | select(.vm_name == $vm) | .ssh_dest | strings | select(length > 0)'); then
  echo "VM creation returned successfully, but its SSH destination could not be resolved. Check 'ssh exe.dev ls' for $vm." >&2
  exit 1
fi

echo "==> Waiting for first boot on $dest"
deadline=$((SECONDS + wait_seconds))
output=''
while (( SECONDS < deadline )); do
  if output=$(ssh "${ssh_options[@]}" -o StrictHostKeyChecking=accept-new -- "$dest" bash -s -- "$revision" 2>&1 <<'CHECK'
set -euo pipefail
state_dir="$HOME/.local/state/dotfiles-bootstrap"
case "$(cat "$state_dir/status" 2>/dev/null || true)" in
  failed) tail -n 35 "$state_dir/setup.log" >&2; exit 1 ;;
  ready) ;;
  *)
    if [[ "$(systemctl show exe-setup.service --property=ActiveState --value)" == failed ]]; then
      journalctl -b -u exe-setup.service --no-pager -n 35 >&2 || true
      exit 1
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
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
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
CHECK
  ); then
    printf '%s\n' "$output"
    echo "==> Ready: ssh $dest"
    exit 0
  else
    result=$?
  fi

  case "$result" in
    75|255) sleep 5 ;;
    *) printf '%s\n' "$output" >&2; break ;;
  esac
done

if (( SECONDS >= deadline )); then
  echo "Timed out waiting for setup on $dest." >&2
  if [[ -n "$output" ]]; then printf '%s\n' "$output" >&2; fi
fi
echo "VM kept for inspection. See ~/.local/state/dotfiles-bootstrap/setup.log on $dest." >&2
exit 1
