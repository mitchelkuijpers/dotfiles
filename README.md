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
- `make unlock`: decrypt secrets with `git-crypt unlock`.
- `make lock`: re-encrypt secrets with `git-crypt lock`.
- `make export-key`: export the git-crypt key as base64 for backup.
- `make import-key`: restore the git-crypt key from a base64 backup.

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

## Secrets management

Secrets are stored encrypted in git using `git-crypt`. Files under
`secrets/` are automatically encrypted at rest and decrypted on disk
after `git-crypt unlock`.

### First-time setup (already done)

`git-crypt` is initialized and `secrets/` is configured for encryption
via `.gitattributes`.

### Backing up the key

The git-crypt key lives in `.git/git-crypt/keys/default` and is **not**
tracked by git. If lost, secrets are unrecoverable.

```bash
make export-key
```

This writes `git-crypt-key-backup.b64` (a base64-encoded key). Store the
file contents in Bitwarden (or any password manager) as a secure note.
The `.b64` file is gitignored and will not be committed.

### Restoring on a new machine

1. Clone the repository.
2. Save the base64 key from Bitwarden to `git-crypt-key-backup.b64`
   in the repo root.
3. Run:

```bash
make import-key
```

This decodes the key and unlocks the repository. After this, `make switch`
will work as normal.

### Adding a new secret

1. Create a plaintext file under `secrets/` (e.g. `secrets/api-key`).
2. Add an option and read the file in `secrets/default.nix`:

   ```nix
   mySecrets.apiKey = builtins.readFile ./api-key;
   ```

3. Reference it via `config.mySecrets.apiKey` or expose it as a session
   variable in the same module.
4. Commit the file — git-crypt encrypts it transparently.
