# AGENTS.md

Guidance for coding agents working in this dotfiles repository.

## Scope

- Repo type: Home Manager + Nix flake configuration
- Primary target host: `aarch64-darwin` (see `flake.nix`)
- Main Home Manager entry: `homeConfigurations.mitkuijp`

## Repository layout

- `flake.nix` - flake inputs/outputs and nixpkgs config
- `hosts/` - host-specific entrypoints (`username`, `homeDirectory`, selected profile)
- `profiles/` - profile composition (`base`, `dev`, ...)
- `modules/` - focused Home Manager modules (programs/common)
- `assets/` - linked config assets (e.g. tmuxinator files)

## Common commands

Run from repo root:

- `make switch` - apply Home Manager config
- `make build` - build activation package
- `make check` - run flake checks
- `make fmt` - format Nix files with alejandra
- `make lint` - run statix + deadnix
- `make update` - update `flake.lock`

## Editing guidelines

1. Keep changes minimal and scoped.
2. Prefer module edits over host/profile edits unless behavior is host/profile-specific.
3. Do not casually bump `home.stateVersion`.
4. Preserve compatibility shims unless explicitly asked (example: tmux compatibility file in `modules/programs/tmux.nix`).
5. Keep comments that explain non-obvious behavior.

## Package management conventions

### Regular packages

- Add packages to `modules/common/packages.nix` under `home.packages`.
- If package is unfree, allow it in `flake.nix` via `config.allowUnfreePredicate`.

### Pinned npm CLI packages

This repo uses `mkPinnedNpmCli` in `modules/common/packages.nix`.

- Use `fetchurl` (not `fetchzip`) for npm tarballs.
- Set `sourceRoot = "package"`.
- Store metadata in `assets/npm-locks/`:
  - `<name>.package.json`
  - `<name>.package-lock.json`
- Wire via `packageFile` + `lockFile` in `mkPinnedNpmCli` call.

## Shell-specific behavior

- Fish defines a `pi` wrapper in `modules/programs/fish.nix` that sets a private npm prefix for pi package installs.
- Avoid reintroducing global `NPM_CONFIG_PREFIX` in `modules/common/env.nix` unless explicitly requested.

## Validation checklist for changes

When possible (on a machine with Nix available):

1. `make fmt`
2. `make lint`
3. `make build`
4. If user asked to apply config: `make switch`

If running in an environment without Nix, make static edits and clearly tell the user which commands to run locally.

## Commit hygiene

- Use small, focused commits.
- Prefer imperative commit messages.
- If user asks for split commits, separate by concern (code fix vs docs vs shell behavior).
