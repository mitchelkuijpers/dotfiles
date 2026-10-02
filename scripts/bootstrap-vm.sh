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
ssh "$dest" bash -se -- "$cfg_override" <<'REMOTE'
set -euo pipefail

user_name="$(id -un)"
cfg="${1:-}"
if [ -z "$cfg" ]; then
  # Map (user, arch) to a flake config; extend when adding hosts.
  case "$user_name:$(uname -m)" in
    exedev:x86_64)                cfg=exedev ;;
    exedev:aarch64|exedev:arm64)  cfg=exedev-arm ;;
    root:x86_64)                  cfg=shellbox ;;
    *) echo "no config for $user_name:$(uname -m) - pass one explicitly" >&2; exit 1 ;;
  esac
fi
has_systemd=$([ -d /run/systemd/system ] && echo yes || echo no)
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
# home-manager's activation script references $USER directly; raw shells
# (docker exec, cron) may not have it.
export USER="${USER:-$user_name}"
echo "user=$user_name config=$cfg systemd=$has_systemd"

if ! [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  echo "--> installing Nix (Determinate installer)"
  if [ "$has_systemd" = yes ]; then
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install linux --no-confirm
  else
    # No systemd (container): install without an init service, start the
    # daemon manually below.
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install linux --no-confirm --init none
  fi
fi

if ! grep -q cache.numtide.com /etc/nix/nix.conf 2>/dev/null; then
  echo "--> trusting numtide cache system-wide"
  echo 'extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=' \
    | $SUDO tee -a /etc/nix/nix.conf >/dev/null
  if [ "$has_systemd" = yes ]; then
    $SUDO systemctl restart nix-daemon
  fi
fi

if [ "$has_systemd" = no ] && ! pgrep -x nix-daemon >/dev/null 2>&1; then
  echo "--> starting nix-daemon (no systemd)"
  $SUDO sh -c 'nohup /nix/var/nix/profiles/default/bin/nix-daemon >/var/log/nix-daemon.log 2>&1 &'
  sleep 3
fi

# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

echo "--> home-manager switch ($cfg)"
cd ~/dotfiles
nix run . -- switch --flake ".#$cfg" -b backup

fish_path="$HOME/.nix-profile/bin/fish"
if [ -x "$fish_path" ]; then
  grep -qxF "$fish_path" /etc/shells 2>/dev/null || echo "$fish_path" | $SUDO tee -a /etc/shells >/dev/null
  current_shell=$(getent passwd "$user_name" | cut -d: -f7)
  if [ "$current_shell" != "$fish_path" ]; then
    echo "--> chsh to $fish_path"
    $SUDO chsh -s "$fish_path" "$user_name"
  fi
fi

echo "--> done. Log in again for fish + nix PATH."
REMOTE

echo "==> $dest bootstrapped: ssh $dest"
