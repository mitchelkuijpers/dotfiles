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
- `make vm VM=<ssh-dest>`: bootstrap or update an agent VM (Ubuntu, e.g. exe.dev) with the same tooling. See `plans/agent-vms.md`.

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

### OMP authentication services and Pi

OMP is pinned independently to **18.12.5** through the `omp-agents` flake input,
without changing Pi or the other `llm-agents` packages. To change OMP versions,
select a suitable `llm-agents.nix` revision in that input, update its lock entry
with `nix flake update omp-agents`, then build before switching. The launchers
use the pinned store executable instead of mise's mutable `latest`.

Remove `"github:can1357/oh-my-pi" = "latest"` from `~/.config/mise/config.toml`
to prevent mise's shim from shadowing Nix when invoking plain `omp`. Leave the
other mise tool entries unchanged.

The Mac profile runs OMP's auth broker on `127.0.0.1:18765` and auth gateway
on `127.0.0.1:18766` as Home Manager LaunchAgents. The gateway waits for broker
health before starting; launchd restarts failed services with a throttle.
Both listeners remain local and retain bearer authentication.

The credential vault and tokens remain writable under `~/.omp`, outside the
Nix store. Do not put raw tokens in Nix settings or session variables.
The gateway reads the broker token from `~/.omp/auth-broker.token`; Pi reads
only `~/.omp/auth-gateway.token` at runtime. OAuth login remains an interactive
operation with `omp auth-broker login`.
Nix sets `OMP_AUTH_BROKER_URL=http://127.0.0.1:18765` for the gateway
LaunchAgent and `nono-omp`, not globally in the shell, and does not export
`OMP_AUTH_BROKER_TOKEN`. The launcher sets the URL inside the sandbox so
nono's environment filtering cannot remove it. OMP reads the broker token
from `~/.omp/auth-broker.token`; direct broker access exposes provider
credentials to OMP, unlike gateway access. An inherited broker token overrides
file-based token resolution. Plain `omp` is unchanged.

For custom broker-backed providers in `~/.omp/agent/models.yml`, remove pinned
`apiKey` overrides. In OMP 18.12.5, static custom models require `auth: none`
when no config key or OAuth flow is supplied; broker credentials still take
precedence over the keyless fallback. For Nebul this lets the broker supply
the key without requiring `NEBUL_API_KEY` inside nono. Leaving
`apiKey: NEBUL_API_KEY` would override the broker and send the variable name
as the literal key when nono filters that environment variable.

Pi's `omp-gateway` provider discovers chat models from the gateway's
authenticated `/v1/models` endpoint. Its default is
`openai-codex/gpt-6-sol` with `medium` thinking; Synthetic remains available.
No second model list is maintained in Pi. OMP's served catalog, rather than
local `models.yml` overrides, determines the gateway's advertised models.
Pi fetches the catalog at extension startup and during model refresh; gateway
or authentication failures are reported instead of adding a fake model.
The gateway supplies availability and limits; Pi's bundled metadata supplies
known reasoning capabilities and pricing. Unknown prices display as zero,
not a guarantee of free inference.
These gateway defaults and the extension are Mac-only; Linux agent profiles
retain their existing Synthetic defaults.

When running Pi under nono, its profile must permit the gateway connection
and reading the gateway-token file; managing Pi's settings does not expand
the sandbox policy.

Before the first `make switch`, stop any manually started broker and gateway
so they do not occupy the same ports. Switching installs the LaunchAgents;
they subsequently start at login, not before login or while the Mac sleeps.
Never run a second broker against the same vault for this cutover.

Service output is written to `~/Library/Logs/omp-auth-{broker,gateway}.log`
and the corresponding `.error.log` files. Restart a managed service with
`launchctl kickstart -k gui/$(id -u)/org.nix-community.home.omp-auth-gateway`
(replace `gateway` with `broker` for the broker). Restart services after
rotating their token files so they load the new token.

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
