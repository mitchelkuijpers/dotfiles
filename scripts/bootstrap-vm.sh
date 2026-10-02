#!/usr/bin/env bash
# Bootstrap an agent VM (exe.dev or any Ubuntu VM with ssh + sudo) with this
# flake's tooling. Idempotent: safe to re-run for updates.
#
#   ./scripts/bootstrap-vm.sh <ssh-dest>      e.g. my-vm.exe.xyz
#
# What it does on the VM (as the ssh'd user):
#   1. rsync this repo to ~/dotfiles (plain path flake; .git excluded so the
#      remote always sees the working tree as-is, including uncommitted edits)
#   2. install Nix (Determinate installer) if absent
#   3. trust the numtide cache system-wide — flake nixConfig public keys are
#      ignored for untrusted users, and without them the llm-agents packages
#      build from source (codex is a large Rust build)
#   4. home-manager switch with the right config for `uname -m`
#   5. make the HM-managed fish the login shell (/etc/shells + chsh)
set -euo pipefail

dest="${1:-}"
if [[ -z "$dest" ]]; then
  echo "usage: $0 <ssh-dest>   (e.g. $0 my-vm.exe.xyz)" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> syncing repo to $dest:~/dotfiles"
ssh "$dest" 'mkdir -p ~/dotfiles'
rsync -a --delete --exclude .git/ "$repo_root/" "$dest:dotfiles/"

echo "==> bootstrapping $dest"
ssh "$dest" 'bash -se' <<'REMOTE'
set -euo pipefail

arch=$(uname -m)
case "$arch" in
  x86_64)        cfg=exedev ;;
  aarch64|arm64) cfg=exedev-arm ;;
  *) echo "unsupported arch: $arch" >&2; exit 1 ;;
esac
has_systemd=$([ -d /run/systemd/system ] && echo yes || echo no)
echo "arch=$arch config=$cfg systemd=$has_systemd"

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
    | sudo tee -a /etc/nix/nix.conf >/dev/null
  if [ "$has_systemd" = yes ]; then
    sudo systemctl restart nix-daemon
  fi
fi

if [ "$has_systemd" = no ] && ! pgrep -x nix-daemon >/dev/null 2>&1; then
  echo "--> starting nix-daemon (no systemd)"
  sudo sh -c 'nohup /nix/var/nix/profiles/default/bin/nix-daemon >/var/log/nix-daemon.log 2>&1 &'
  sleep 3
fi

# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

echo "--> home-manager switch ($cfg)"
cd ~/dotfiles
nix run . -- switch --flake ".#$cfg" -b backup

fish_path="$HOME/.nix-profile/bin/fish"
if [ -x "$fish_path" ]; then
  grep -qxF "$fish_path" /etc/shells 2>/dev/null || echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [ "$current_shell" != "$fish_path" ]; then
    echo "--> chsh to $fish_path"
    sudo chsh -s "$fish_path" "$USER"
  fi
fi

echo "--> done. Log in again for fish + nix PATH."
REMOTE

echo "==> $dest bootstrapped: ssh $dest"
