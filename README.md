# Dotfiles

This repository manages local developer setup with Home Manager + Nix flakes.

## Structure

- `flake.nix`: flake inputs/outputs and Home Manager entries.
- `hosts/`: host-specific configuration (`username`, `homeDirectory`, selected profile).
- `profiles/`: composable bundles (`base`, `dev`, `work`).
- `modules/`: focused Home Manager modules grouped by area.
- `assets/`: non-Nix config assets linked into XDG locations.

## Usage

- `make switch`: apply the current profile.
- `make build`: build the activation package.
- `make check`: run flake checks.
- `make fmt`: format Nix files with alejandra.
- `make lint`: run `statix` and `deadnix`.
- `make update`: update `flake.lock`.
