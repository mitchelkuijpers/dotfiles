#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "$0")/../.." && pwd)
kit=$(mktemp -d "$repo/result-docker-sandbox-kit.XXXXXX")/home-shell
config="$kit/config"

mkdir -p "$config/hosts/docker-sandbox" "$config/modules/programs" "$config/assets/rex"
cp "$repo"/sandboxes/docker/home-shell/home-shell.{yaml,dockerfile} "$kit/"
cp "$repo"/flake.{nix,lock} "$config/"
cp "$repo/hosts/docker-sandbox/home.nix" "$config/hosts/docker-sandbox/"
cp "$repo"/modules/programs/{fish-shared,fzf,pi-shared,rex,starship}.nix "$config/modules/programs/"
cp "$repo/assets/rex/init.lua" "$config/assets/rex/"
printf '%s
' "$kit"
