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

Use this when nixpkgs is missing/outdated for a global npm CLI.

Preferred workflow:

1. Run the helper:
   - new package: `make pin-npm PACKAGE=@scope/name VERSION=1.2.3`
   - existing package: `make pin-npm ATTR=piCodingAgent VERSION=0.56.2`
2. The helper will:
   - resolve the tarball URL from npm
   - compute the `fetchurl` hash
   - refresh `assets/npm-locks/<lock-name>.package.json`
   - refresh `assets/npm-locks/<lock-name>.package-lock.json`
   - upsert `assets/npm-locks/pinned-packages.json`
3. All pinned npm CLIs declared in `assets/npm-locks/pinned-packages.json` are installed automatically by `modules/common/packages.nix`, so new entries do not need a separate package list edit.
4. Validate with `make lint` and `make build`.
5. Apply with `make switch`.

Optional overrides:

- `ATTR=<attr>` sets the Nix attribute name stored in `pinned-packages.json`.
- `PNAME=<pname>` overrides the derivation/package base name.
- `LOCK_NAME=<name>` overrides the `assets/npm-locks/<name>.*` file prefix.

Manual fallback:

1. Pick a version and tarball URL:
   - `npm view <package> version dist.tarball --json`
2. Compute tarball hash:
   - `npm pack <package>@<version>`
   - `openssl dgst -sha256 -binary <tarball.tgz> | openssl base64 -A`
3. Generate lock metadata from the tarball:
   - extract `package/package.json` into `assets/npm-locks/<name>.package.json`
   - run `npm install --package-lock-only --ignore-scripts` in extracted sources
   - save lock to `assets/npm-locks/<name>.package-lock.json`
4. Add or update the entry in `assets/npm-locks/pinned-packages.json`.
5. Apply with `make switch`.

Current examples:
- `piCodingAgent`
- `opencodeAi`
