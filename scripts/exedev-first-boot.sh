#!/bin/bash
set -euo pipefail

revision='@DOTFILES_REV@'
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Expected vm-new to insert a full dotfiles commit SHA.' >&2
  exit 1
fi

checkout="$HOME/dotfiles"
state_dir="$HOME/.local/state/dotfiles-bootstrap"
origin='https://github.int.exe.xyz/mitchelkuijpers/dotfiles.git'
umask 077
mkdir -p "$state_dir"
exec >> "$state_dir/setup.log" 2>&1

write_status() {
  printf '%s\n' "$1" > "$state_dir/status.tmp"
  mv -f "$state_dir/status.tmp" "$state_dir/status"
}

incoming=''
finish() {
  local result=$?
  if [[ -n "$incoming" ]]; then
    rm -rf -- "$incoming" || true
  fi
  if (( result == 0 )); then
    write_status ready
  else
    write_status failed
  fi
}
trap finish EXIT
write_status running
echo "==> Setting up dotfiles revision $revision"

if [[ ! -e "$checkout" ]]; then
  incoming=$(mktemp -d "$HOME/.dotfiles-bootstrap.XXXXXX")
  git -C "$incoming" init -q
  git -C "$incoming" remote add origin "$origin"
  # Allow the tag's GitHub integration to become available during first boot.
  export GIT_TERMINAL_PROMPT=0
  for delay in 1 2 4 8 16 0; do
    if git -C "$incoming" fetch --depth=1 origin "$revision"; then
      break
    fi
    if (( delay == 0 )); then
      echo "Could not fetch $revision. Check that it is published and the GitHub integration is attached to tag:agent."
      exit 1
    fi
    sleep "$delay"
  done
  git -C "$incoming" -c advice.detachedHead=false checkout --detach "$revision"
  mv -T -- "$incoming" "$checkout"
  incoming=''
fi

if [[ ! -d "$checkout/.git" ]] \
  || [[ "$(git -C "$checkout" rev-parse HEAD)" != "$revision" ]] \
  || [[ -n "$(git -C "$checkout" status --porcelain --untracked-files=no)" ]]; then
  echo "Expected a clean checkout of $revision at $checkout." >&2
  exit 1
fi

# Home Manager and the tools it installs should use the guest's normal umask.
umask 022
bash "$checkout/scripts/setup-vm.sh"
