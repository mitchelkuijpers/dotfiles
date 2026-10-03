---
name: agent-environment
description: How to browse, test, and run services from an agent session on this Linux VM. Use when asked to browse the web, drive or screenshot a page, run Playwright, test a local dev app, run Docker, or expose a port. There is no sandbox here — you may run browsers, servers, and containers directly.
---

# Agent environment (Linux VM)

This is a full Linux VM, **not** a sandboxed session. There is no Seatbelt/
nono layer, no host services to attach to, and no prohibition on launching
browsers or daemons. Run things directly.

> The macOS `agent-environment` skill does not apply here. If you find
> instructions about `agent-browser`, `127.0.0.1:13306`, a Playwright
> run-server on `:3000`, or `~/.colima-agent.sock`, ignore them — those
> describe the Mac, not this machine.

## What you can do here

- **Install anything.** `sudo` is available (exe.dev: passwordless). The flake
  provides tools such as `pnpm`, `docker`, and `gh`; use per-project `mise` for
  Node/Go/Python toolchains, or `apt`/`nix` for other dependencies.
- **Run browsers directly.** There is nothing stopping a headless Chromium.
  For Playwright:
  ```sh
  npx -y playwright@1.63.0 install --with-deps chromium
  ```
  Then `chromium.launch()` works normally. No CDP endpoint or run-server.
- **Run servers and long-lived processes** with `nohup`/`tmux`; tmux (with
  fish) is installed. Do not block on a foreground server.
- **Run Docker** — see below.

## Docker

Docker the CLI is installed by the flake. Check whether a daemon is actually
reachable before using it:

```sh
docker info >/dev/null 2>&1 && echo "daemon up" || echo "no daemon"
```

- **exe.dev (`exeuntu` image):** Docker works out of the box —
  `docker run --rm alpine:latest echo hello`. There is no `docker-up`; the
  daemon is already running.
- **Other Ubuntu VMs (e.g. shellbox):** a daemon may not be installed. Start
  one with `sudo apt-get install -y docker.io && sudo systemctl start docker`
  (or use `dockerd` directly). These are KVM guests **without nested
  virtualization**, so Docker works but a VM-inside-a-VM will not.

Private registries on exe.dev go through an integration hostname
(`docker pull <name>.int.exe.xyz/...`) — no `docker login` needed. See the
`ghcr`/`quay` integration docs.

## Exposing a port (exe.dev)

Any service you bind on the VM is reachable over HTTPS by the VM owner:

- Default share port for `exeuntu` is **8000** → `https://<vm>.exe.xyz/`
- Ports **3000–9999** are forwarded to `https://<vm>.exe.xyz:<port>/`
- Private (login required) by default; `ssh exe.dev share set-public <vm>`
  makes the single chosen port public.

So to show someone a dev server, bind it and hand them the `exe.xyz` URL —
do not try to tunnel out.

## Testing local dev apps

Bind the app on the VM (`0.0.0.0` or `127.0.0.1` both work for the proxy);
then drive it with a locally-launched browser or `curl`. Secure-context APIs
work over the proxied HTTPS URL.
