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

### 2) Pinned npm CLI packages (latest npm, reproducible in Nix)

This repo has a helper in `modules/common/packages.nix` called `mkPinnedNpmCli`.
Use it when nixpkgs is missing/outdated for a global npm CLI.

Steps:

1. Pick a version and tarball URL:
   - `npm view <package> version dist.tarball --json`
2. Compute tarball hash (Nix-style base64 SHA256, used with `fetchurl`):
   - `npm pack <package>@<version>`
   - `openssl dgst -sha256 -binary <tarball.tgz> | openssl base64 -A`
3. Generate lock metadata from the tarball:
   - extract `package/package.json` into `assets/npm-locks/<name>.package.json`
   - run `npm install --package-lock-only --ignore-scripts` in extracted sources
   - save lock to `assets/npm-locks/<name>.package-lock.json`
4. Add a new `mkPinnedNpmCli { ... }` entry in `modules/common/packages.nix` with:
   - `pname`, `version`, `url`, `hash`, `packageFile`, `lockFile`
5. Add that derivation to `home.packages`.
6. Apply with `make switch`.

Current examples:
- `piCodingAgent`
- `opencodeAi`
