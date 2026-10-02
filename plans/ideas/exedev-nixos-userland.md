# Idea: exe.dev NixOS userland image

Status: idea — parked for later. The current Ubuntu + standalone
home-manager setup (see ../agent-vms.md) covers the need for now.
Parked: 2026-10-02.

## What

Replace the exe.dev Ubuntu bootstrap with a **custom exe.dev image that is a
full NixOS userland with our home-manager config baked in**. New VMs would
boot fully configured — no rsync, no Nix install, no bootstrap.

Reference: exe.dev's own prototype,
<https://github.com/boldsoftware/exe.dev/blob/main/nix/> — build a NixOS
closure tarball inside a `nixos/nix` Docker container, ship it as an OCI
image (`ssh exe.dev new --image=...`).

## Facts learned from their prototype

- exe.dev "VMs" are OCI userlands: exe.dev supplies the kernel and runs
  `/exe.dev/bin/exe-init` (NIC, routes, DNS, hostname, hosts) before handing
  PID 1 to the image's `/init`.
- Consequences for NixOS: disable DHCP/resolvconf/firewall/sshd; keep an
  `sshd` priv-sep user; use `docker-container.nix` profile.
- SSH keys are injected out-of-band by exe.dev's embedded daemon →
  `users.mutableUsers = false`, `users.allowNoPasswordLogin = true`.
- `LABEL exe.dev/login-user=exedev` picks the login user.
- `exe-shell` PATH wrapper so command-mode ssh (`ssh vm 'cmd'`) sees the
  nix profile paths.
- Their Dockerfile: `nixos/nix` builder image → `nix-build` the system
  tarball → `FROM scratch` OCI image with `/etc/passwd`, `/etc/group`,
  `/bin/{sh,bash}` symlinks to exe-shell.

## Our take (when picked up)

- `nixosConfigurations.exe-nixos` (aarch64-linux + x86_64-linux) in the
  flake; home-manager as a NixOS module pointing at the same
  `hosts/exedev/home.nix`, with `targets.genericLinux.enable` forced off
  (NixOS handles that).
- System-level config adapted from their configuration.nix, but via our
  flake inputs (nixpkgs-unstable + llm-agents cache) instead of their
  pinned NIXPKGS_REV.
- `scripts/build-exe-image.sh`: build inside a `nixos/nix` container on
  colima (dogfooded: nix-in-docker works, aarch64 natively, x86_64 via
  rosetta) → push → `ssh exe.dev new --image=...`.
- The Ubuntu bootstrap path (scripts/bootstrap-vm.sh) stays as the generic
  fallback for non-exe.dev VMs.

## Security caveat

A flake build copies the whole source tree into the nix store → into the
image. The repo dir contains decrypted secrets when git-crypt is unlocked.
Never push an image with unlocked git-crypt to a public registry. Options:

- private registry (ghcr + `exe.dev new --registry-auth`) — robust choice;
- ttl.sh (public, 24h) only with git-crypt locked / secrets excluded.

## Open decision (when picked up)

- Registry: ttl.sh vs private ghcr (see above).
- Whether HM lives in the NixOS module (baked, atomic) vs still switchable
  on the VM (both true either way; question is the update workflow).
