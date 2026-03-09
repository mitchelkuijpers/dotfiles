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

## Adding dependencies

### 1) Regular Nix packages

Most CLI tools are added in `modules/common/packages.nix` under `home.packages`.

1. Add the package attr name (for example `jq`, `terraform-ls`, `cljfmt`).
2. Apply with `make switch`.

If a package is marked unfree (for example `terraform`), allow it in `flake.nix` via `config.allowUnfreePredicate`.

### 2) AI coding agents

This setup installs `opencode` and `pi` from `numtide/llm-agents.nix` in `modules/common/packages.nix`.

To update those versions, refresh the flake lock:

1. Run `make update` (or `nix flake lock --update-input llm-agents`).
2. Validate with `make lint` and `make build`.
3. Apply with `make switch`.
