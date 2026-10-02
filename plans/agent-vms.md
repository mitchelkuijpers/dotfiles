# Agent VMs via Nix

Status: bootstrap validated end-to-end in a local aarch64 Ubuntu container
(via colima Docker). Phases 1–3 done; remaining: run against a real exe.dev
VM, polish.
Owners: mitkuijp + pi

## Goal

Provision "agent VMs" (Ubuntu on exe.dev, plus local/remote Ubuntu VMs) from
this flake with the same tooling as the macOS setup: same shells, editors,
git config, and AI agent CLI tooling (pi, opencode, ...) — so an agent
session inside a VM feels identical to one on the Mac.

## Decisions (resolved via Hunk review, 2026-10-02)

1. **Target: Ubuntu VMs, not NixOS.** Deploy to exe.dev and existing Ubuntu
   VMs (remote or local). → Use **standalone Home Manager on Linux**
   (`homeConfigurations`), no `nixosConfigurations`.
2. **Builder: the VM builds itself.** No cross-building from the Mac.
   Bootstrap = install Nix on the VM, then run `home-manager switch` there.
   Pure flake evaluation still gets verified from the Mac (`nix eval`).
3. **Secrets: none on agent VMs.** `mySecrets.enable` stays off. The repo
   reaches the VM via rsync/ssh from the Mac — no credentials stored on VMs.

### exe.dev facts (from docs)

- Default image `exeuntu` = Ubuntu 24.04 + systemd; default login user
  `exedev` (home `/home/exedev`). Root/sudo available.
- VMs reachable as `<name>.exe.xyz`; API is ssh (`ssh exe.dev new`, `ls`,
  `defaults write`, ...).
- `--setup-script` (max 10 KiB) runs at first boot — usable for bootstrap.
- Custom Docker images supported (`new --image=`), incl. labels like
  `exe.dev/login-user`.
- claude, codex, pi come preinstalled on exeuntu; we still manage our own
  pinned versions via the flake (parity > convenience).
- Arch: the public `ghcr.io/boldsoftware/exeuntu` image is multi-arch
  (amd64 + arm64 manifests) → per-VM arch depends on the host; `uname -m`
  on the VM settles it. **Support both `x86_64-linux` and `aarch64-linux`**
  via two homeConfigurations (bootstrap picks by `uname -m`).

## Architecture

```
flake.nix
  homeConfigurations.mitkuijp   # macOS, unchanged
  homeConfigurations.exedev     # linux, exe.dev user, x86_64-linux
  homeConfigurations.exedev-arm # linux, exe.dev user, aarch64-linux
  packages.<system>.default     # home-manager CLI, per system (aarch64-darwin,
                                #   x86_64-linux, aarch64-linux) so
                                #   `nix run . -- switch` works on the VM too

hosts/exedev/home.nix           # username exedev, /home/exedev,
                                # targets.genericLinux.enable = true,
                                # imports profiles/agent.nix, own stateVersion,
                                # mySecrets off
profiles/agent.nix              # base + linux-safe dev tooling
scripts/bootstrap-vm.sh         # Mac-driven: rsync repo, install nix, switch
```

Validated up front:

- All llm-agents.nix packages we use (pi, opencode2, codex, tuicr, hunk,
  terminal-browser) exist for both `x86_64-linux` and `aarch64-linux`.
- `programs.pi-coding-agent` is an upstream home-manager module → portable.

## Portability refactor (phase 1 — no behavior change on the Mac)

### modules/common/packages.nix

Guard darwin-only entries with `lib.optionals pkgs.stdenv.isDarwin`:

- darwin-only: `terminal-notifier`, `freelens-bin`, the `nono-*` wrappers
  (reference macOS-specific `~/.config/nono` profiles; nono-on-linux is a
  possible follow-up).

### modules/common/env.nix

Keep portable: `EDITOR`/`VISUAL`/`LANG`, `PNPM_HOME`, pnpm path entry.
Move to a new darwin-only host module under `hosts/mitkuijp-macbook/`:
`/opt/homebrew` PATH entries, personal `KUBECONFIG`, `CONNECT__BASEURL`.

### modules/programs/pi.nix

- Guard the nono package source (`/Users/mitkuijp/.config/nono/...`) with
  `lib.mkIf pkgs.stdenv.isDarwin` (via `lib.mkMerge` on the packages list).
- Guard the Playwright→host-Chrome `mcp.json` the same way (depends on
  `modules/common/agent-environment.nix`, which is mac-only: `open -na`,
  host Chrome).
- Pi without API keys on the VM: fine for now (Decision 3) — models can be
  enabled later by scoping `synthetic-api-key` to agent hosts.

## Bootstrap flow (phase 3)

`scripts/bootstrap-vm.sh <ssh-dest>` run from the Mac:

1. `rsync` the repo to `~/dotfiles` on the VM (plain-path flake; safe even
   with locked git-crypt secrets since agent hosts never read them).
2. ssh: install Nix if absent — Determinate Systems installer, one command,
   flakes enabled by default: `... | sh -s -- install linux --no-confirm`
   (add `--init none` + manual nix-daemon when there's no systemd, e.g.
   containers). Then trust the numtide cache in `/etc/nix/nix.conf`
   (extra-substituters + extra-trusted-public-keys) — dogfooding showed the
   llm-agents packages otherwise build from source, because flake nixConfig
   public keys are ignored for untrusted users. On the Mac the same keys
   live in ~/.local/share/nix/trusted-settings.json.
3. ssh: `cd ~/dotfiles && nix run . -- switch --flake .#exedev[_-arm] -b backup`
   (config chosen via `uname -m`: x86_64 → `exedev`, arm64/aarch64 → `exedev-arm`).
4. ssh: make fish the login shell — append `~/.nix-profile/bin/fish` to
   `/etc/shells`, then `sudo chsh -s ~/.nix-profile/bin/fish exedev`
   (skip if already done; bootstrap is idempotent).

Updates: same script (idempotent), or `make vm-switch HOST=name.exe.xyz`.

exe.dev integration: wrap creation as
`ssh exe.dev new --name <n>` then run the bootstrap against `<n>.exe.xyz`.
Later (optional): a custom exe.dev image with Nix preinstalled + setup
script, cutting bootstrap to seconds.

## Phases

1. **Portability guards** ✅ — refactor done; generation verified
   byte-identical on the Mac (except pi package-list reordering).
   NOTE: `make switch` itself still needs to be run outside the nono
   sandbox (it writes ~/.local/state/nix + dotfiles across $HOME).
2. **Agent profile + exedev host + per-system flake** ✅ — all three
   homeConfigurations evaluate from the Mac.
3. **Bootstrap + dogfood** ✅ (local) — `scripts/bootstrap-vm.sh` validated
   end-to-end in a clean Ubuntu 24.04 aarch64 container: Nix install →
   numtide cache trust → `home-manager switch` → fish login shell.
   Remaining: first real exe.dev VM (`ssh exe.dev new --name agent-test`,
   then `make vm VM=agent-test.exe.xyz`).
4. **Polish** — Makefile target ✅ (`make vm`), README section ✅.
   Remaining: optional custom exe.dev image with Nix preinstalled.

## Validation checklist (per AGENTS.md)

1. `make fmt`
2. `make lint`
3. `make build`
4. `nix flake check`
5. `nix eval` of the new homeConfiguration for both linux systems
6. New `.nix` files must be `git add`-ed before nix can see them.

## Open questions (small)

- Username on the local Ubuntu VMs — if not `exedev`, add another host
  entry later (`homeConfigurations.<user>`).
- exe.dev VMs have sudo without password? (bootstrap assumes NOPASSWD or
  interactive sudo; verify on first real run).

## Settled details

- fish **is** the login shell on VMs (bootstrap handles /etc/shells + chsh).
- Nix installer on VMs: Determinate Systems installer.
- exe.dev arch: both supported; bootstrap selects config via `uname -m`.
