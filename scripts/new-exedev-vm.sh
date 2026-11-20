#!/usr/bin/env bash
# Run on the controller, typically the Mac. The new VM builds its own profile.
set -euo pipefail

check_only=false
if [[ "${1:-}" == --check ]]; then
  check_only=true
  shift
fi
vm=${1:-${VM:-}}
revision=${2:-${REV:-}}
wait_seconds=${VM_WAIT_SECONDS:-1200}
disk=${VM_DISK:-}
# Bash 3.2 on macOS needs grouped regular expressions in variables.
vm_pattern='^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'
disk_pattern='^[1-9][0-9]*(GB|TB)$'
if [[ ! "$vm" =~ $vm_pattern || ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Usage: make vm-new|vm-check VM=dev-pilot REV=<full published commit SHA>' >&2
  exit 2
fi
if [[ ! "$wait_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo 'VM_WAIT_SECONDS must be a positive integer.' >&2
  exit 2
fi
create_args=(new --name="$vm" --tag=agent)
if [[ -n "$disk" ]]; then
  if [[ ! "$disk" =~ $disk_pattern ]]; then
    echo 'VM_DISK must be a size such as 40GB.' >&2
    exit 2
  fi
  create_args+=(--disk="$disk")
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ssh_options=(-o BatchMode=yes -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2)
command -v jq >/dev/null || { echo 'jq is required on the controller.' >&2; exit 1; }
inventory=$(ssh "${ssh_options[@]}" exe.dev ls --json)
if ! "$check_only"; then
  if jq -e --arg vm "$vm" '.vms | any(.vm_name == $vm)' <<< "$inventory" >/dev/null; then
    echo "A VM named $vm already exists. Choose a fresh name for its replacement." >&2
    exit 1
  fi
  if ! git -C "$script_dir/.." cat-file -e "$revision:scripts/setup-vm.sh" \
    || ! setup_script=$(git -C "$script_dir/.." show "$revision:scripts/exedev-first-boot.sh"); then
    echo 'The selected commit must include the fleet pilot scripts. Fetch or commit the pilot before creating a VM.' >&2
    exit 1
  fi

  echo "==> Creating $vm with tag agent at dotfiles revision $revision"
  printf '%s\n' "${setup_script//@DOTFILES_REV@/$revision}" \
    | ssh "${ssh_options[@]}" exe.dev "${create_args[@]}" --setup-script /dev/stdin
  inventory=$(ssh "${ssh_options[@]}" exe.dev ls --json)
fi

if ! dest=$(jq -er --arg vm "$vm" '.vms[] | select(.vm_name == $vm) | .ssh_dest | strings | select(length > 0)' <<< "$inventory"); then
  echo "Could not resolve an SSH destination for $vm. Check 'ssh exe.dev ls'." >&2
  exit 1
fi

echo "==> Waiting for first boot on $dest"
deadline=$((SECONDS + wait_seconds))
output=''
while (( SECONDS < deadline )); do
  if output=$(ssh "${ssh_options[@]}" -o StrictHostKeyChecking=accept-new -- "$dest" bash -s -- "$revision" \
    2>&1 < "$script_dir/check-exedev-vm.sh"); then
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
