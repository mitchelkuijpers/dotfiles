---
name: agent-environment
description: How to use browsers, Playwright (Chromium/Firefox/WebKit, CDP) and Docker from agent sessions on this machine. Use when asked to browse the web, drive or screenshot a page, run Playwright scripts/suites, test a local dev app on localhost, or use docker containers. Browsers must never be launched locally by the agent — connect to the host services instead.
---

# Agent environment (this machine)

## Rule zero: never launch a browser yourself

GUI browsers (Chrome/Chromium/Firefox/WebKit) **crash when launched from a
sandboxed agent session** — macOS Seatbelt denies the IOKit and mach
services they need (SIGSEGV / SIGABRT at startup; see nolabs-ai/nono#122).
Do not call `chromium.launch()`, do not start Chrome/Firefox processes.
**Connect to the host services below instead.**

## Browser services (host loopback)

| Endpoint            | Service                              | How to attach                                                          |
| ------------------- | ------------------------------------ | ---------------------------------------------------------------------- |
| `127.0.0.1:13306`   | Dedicated Chrome (CDP)               | `chromium.connectOverCDP("ws://127.0.0.1:13306")`                       |
| `127.0.0.1:3000`    | Playwright run-server (`1.63.0`)     | `<browserType>.connect("ws://127.0.0.1:3000/")` — chromium, firefox, webkit |

Guidelines:

- **Automation scripts** (scraping, tests, poking around): prefer the
  run-server on `:3000` — every `connect()` gives a fresh isolated browser
  with clean contexts.
- **Driving/observing the same browser the user sees** (pi browser tools,
  attaching to existing pages): use CDP on `:13306`.
- Playwright clients **must match the server version** (`1.63.0`) or the
  server rejects them with HTTP 428. Pin with `pnpm add -D playwright@1.63.0`
  or `pnpm dlx playwright@1.63.0 ...`.

Health checks:

```sh
curl -sf http://127.0.0.1:13306/json/version   # Chrome CDP: 200 + JSON
curl -sf http://127.0.0.1:3000/                # run-server: 200
```

If a health check fails, the service is not running on the host. **Do not
start browsers yourself** — ask the user to run `agent-browser` and/or
`agent-playwright` in their host shell.

## Testing local dev apps

Apps running on the Mac host are reachable from these browser services as
`http://localhost:PORT` — the services run on the host, so no forwarding or
special hostnames are needed. OIDC/`redirect_uri`s and secure-context APIs
(`crypto.subtle`) work normally.

## Docker for agents

Agents get an isolated Docker without touching the user's main instance:

```sh
export DOCKER_HOST=unix://$HOME/.colima-agent.sock   # colima "agent" VM
docker ps
```

If the socket exists but refuses connections, the colima VM's forwarding
flaked — ask the user to run `crestart agent` on the host (bounces the
launchd-managed VM; containers with `restart: unless-stopped` come back).
