#!/usr/bin/env bash
# Run on the guest from either a Git checkout or a copy of the dotfiles.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
user_name=$(id -un)
user_id=$(id -u)
cfg=${1:-}
if [[ -z "$cfg" ]]; then
  case "$user_name:$(uname -m)" in
    exedev:x86_64) cfg=exedev ;;
    exedev:aarch64|exedev:arm64) cfg=exedev-arm ;;
    root:x86_64) cfg=shellbox ;;
    *) echo "No profile for $user_name:$(uname -m). Pass a profile explicitly." >&2; exit 1 ;;
  esac
fi

sudo_cmd=()
if [[ "$user_id" != 0 ]]; then
  sudo_cmd=(sudo)
fi
has_systemd=$([ -d /run/systemd/system ] && echo yes || echo no)
export USER="${USER:-$user_name}"
echo "user=$user_name config=$cfg systemd=$has_systemd"

if [[ "$has_systemd" == yes && ( "$cfg" == exedev || "$cfg" == exedev-arm ) ]]; then
  if [[ ! -e "/var/lib/systemd/linger/$user_name" ]]; then
    "${sudo_cmd[@]}" loginctl enable-linger "$user_name"
  fi
  export XDG_RUNTIME_DIR="/run/user/$user_id"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
  if [[ ! -S "$XDG_RUNTIME_DIR/bus" ]]; then
    "${sudo_cmd[@]}" systemctl start "user@$user_id.service"
  fi
  if systemctl --user is-enabled --quiet rex.socket; then
    echo 'A socket-activated Rex install is already enabled. Migrate it before applying the Home Manager Rex service.' >&2
    exit 1
  fi
fi

if [[ ! -x /nix/var/nix/profiles/default/bin/nix ]]; then
  echo "--> installing Nix (Determinate installer)"
  install_args=(install linux --no-confirm)
  if [[ "$has_systemd" == no ]]; then
    install_args+=(--init none)
  fi
  curl --proto '=https' --tlsv1.2 --retry 3 -fsSL https://install.determinate.systems/nix \
    | sh -s -- "${install_args[@]}"
fi

if ! grep -q cache.numtide.com /etc/nix/nix.conf 2>/dev/null; then
  echo "--> trusting numtide cache system-wide"
  echo 'extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=' \
    | "${sudo_cmd[@]}" tee -a /etc/nix/nix.conf >/dev/null
  if [[ "$has_systemd" == yes ]]; then
    "${sudo_cmd[@]}" systemctl restart nix-daemon
  fi
fi

if [[ "$has_systemd" == no ]] && ! pgrep -x nix-daemon >/dev/null 2>&1; then
  echo "--> starting nix-daemon (no systemd)"
  "${sudo_cmd[@]}" sh -c 'nohup /nix/var/nix/profiles/default/bin/nix-daemon >/var/log/nix-daemon.log 2>&1 &'
  sleep 3
fi

# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

echo "--> home-manager switch ($cfg)"
NIX_CONFIG="${NIX_CONFIG:-}"$'\naccept-flake-config = true' \
  nix run --no-write-lock-file . -- switch --flake ".#$cfg" -b backup

if [[ "$has_systemd" == yes && ( "$cfg" == exedev || "$cfg" == exedev-arm ) ]]; then
  # Explicit start also covers activation from the system-level first-boot hook.
  systemctl --user start rex.service
fi

fish_path="$HOME/.nix-profile/bin/fish"
if [[ -x "$fish_path" ]]; then
  grep -qxF "$fish_path" /etc/shells 2>/dev/null || printf '%s\n' "$fish_path" | "${sudo_cmd[@]}" tee -a /etc/shells >/dev/null
  current_shell=$(getent passwd "$user_name" | cut -d: -f7)
  if [[ "$current_shell" != "$fish_path" ]]; then
    echo "--> chsh to $fish_path"
    "${sudo_cmd[@]}" chsh -s "$fish_path" "$user_name"
  fi
fi
