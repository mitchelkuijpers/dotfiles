#!/usr/bin/env bash
# Bootstrap an agent VM (exe.dev or any Ubuntu VM with ssh + sudo) with this
# flake's tooling. Idempotent: safe to re-run for updates.
#
#   ./scripts/bootstrap-vm.sh <ssh-dest> [config]
#     e.g. ./scripts/bootstrap-vm.sh my-vm.exe.xyz        (auto: uname -m)
#          ./scripts/bootstrap-vm.sh box@shellbox.dev shellbox
#
# What it does on the VM (as the ssh'd user):
#   1. copy this repo to ~/dotfiles (plain path flake; .git excluded so the
#      remote always sees the working tree as-is, including uncommitted edits).
#      Uses rsync when the remote has it, else tar-over-ssh (stock shellbox
#      images don't ship rsync).
#   2. install Nix (Determinate installer) if absent
#   3. trust the numtide cache system-wide — flake nixConfig public keys are
#      ignored for untrusted users, and without them the llm-agents packages
#      build from source (codex is a large Rust build)
#   4. home-manager switch with the right config for `uname -m`
#   5. make the HM-managed fish the login shell (/etc/shells + chsh)
set -euo pipefail

dest="${1:-}"
cfg_override="${2:-}"
if [[ -z "$dest" ]]; then
  echo "usage: $0 <ssh-dest> [config]   (e.g. $0 my-vm.exe.xyz)" >&2
  exit 1
fi
if [[ -n "$cfg_override" && ! "$cfg_override" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "invalid Home Manager config: $cfg_override" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> syncing repo to $dest:~/dotfiles"
if ssh "$dest" 'command -v rsync >/dev/null 2>&1'; then
  ssh "$dest" 'mkdir -p ~/dotfiles'
  rsync -a --delete --exclude .git/ "$repo_root/" "$dest:dotfiles/"
else
  echo "    (remote has no rsync; using tar)"
  ssh "$dest" 'rm -rf ~/dotfiles && mkdir -p ~/dotfiles'
  tar -c --exclude .git -C "$repo_root" . | ssh "$dest" 'tar -x -C ~/dotfiles'
fi

echo "==> bootstrapping $dest"
# The controller expands the profile name after validating its characters.
# shellcheck disable=SC2029
ssh "$dest" 'bash "$HOME/dotfiles/scripts/setup-vm.sh"' "$cfg_override"

echo "==> $dest bootstrapped: ssh $dest"
