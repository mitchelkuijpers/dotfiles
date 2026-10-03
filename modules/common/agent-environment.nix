# Host services + shared skill for coding agents (pi, opencode, ...).
#
# Sandboxed agent sessions cannot launch browsers (macOS Seatbelt kills them,
# see nolabs-ai/nono#122), so browsers run as plain host processes on loopback
# and agents connect over CDP / the Playwright wire protocol:
#
#   agent-browser    → dedicated Chrome on 127.0.0.1:13306 (CDP endpoint)
#   agent-playwright → playwright run-server on 127.0.0.1:3000 (chromium/firefox/webkit)
#
# Both are on-demand: start them once per host session; the scripts are
# idempotent (no-op when already running).
#
# Agents discover all of this via the cross-vendor Agent Skills standard:
# the single source in ../../assets/agent-environment/SKILL.md is linked into
# ~/.agents/skills, which pi, opencode and other compliant agents discover
# natively. Bump the pinned Playwright version in the run-server script AND
# the skill together.
#
# macOS-only. Everything here (nono/Seatbelt browser limits, host Chrome via
# `open`, the colima agent socket) is meaningless on a Linux VM, and the skill
# text is explicitly written for the Mac. Guarded so it can never be handed to
# an agent on an agent VM even if a linux profile ever imports this module.
{
  lib,
  pkgs,
  ...
}: {
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    ".agents/skills/agent-environment/SKILL.md".source = ../../assets/agent-environment/SKILL.md;

    ".local/bin/agent-browser" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Starts (or verifies) the dedicated Chrome for agent browser tools.
        set -euo pipefail
        PORT=13306
        if curl -sf "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
          echo "agent Chrome already running on :$PORT"
          exit 0
        fi
        open -na "Google Chrome" --args \
          --remote-debugging-port="$PORT" \
          --user-data-dir="$HOME/.pi/browser-profile-host" \
          --no-first-run \
          --no-default-browser-check
        for _ in $(seq 1 10); do
          curl -sf "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1 && {
            echo "agent Chrome ready on ws://127.0.0.1:$PORT"
            exit 0
          }
          sleep 1
        done
        echo "Chrome did not expose CDP on :$PORT within 10s." >&2
        echo "If an agent-Chrome instance is already running without the debug port, quit it fully and retry." >&2
        exit 1
      '';
    };

    # Launcher for the Playwright MCP server (used by pi's ~/.pi/agent/mcp.json).
    # Prefers pnpm, falls back to npx then bun, so the MCP server still starts if
    # a given package runner is missing from PATH. Install noise is kept off
    # stdout: MCP speaks JSON-RPC over stdio, so a stray log line on stdout
    # corrupts the protocol. VERSION is pinned; bump it together with the skill.
    ".local/bin/agent-playwright-mcp" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Runs @playwright/mcp attached to the agent Chrome CDP endpoint.
        set -euo pipefail
        VERSION=0.0.83
        CDP_ENDPOINT="''${AGENT_BROWSER_CDP:-http://127.0.0.1:13306}"
        PKG="@playwright/mcp@$VERSION"
        ARGS=(--cdp-endpoint "$CDP_ENDPOINT" "$@")

        if command -v pnpm >/dev/null 2>&1; then
          exec pnpm --silent dlx "$PKG" "''${ARGS[@]}"
        elif command -v npx >/dev/null 2>&1; then
          # npm's default cache is ~/.npm, which nono mounts read-only; point it
          # at a writable XDG cache unless the user already chose one.
          export npm_config_cache="''${npm_config_cache:-''${XDG_CACHE_HOME:-$HOME/.cache}/npm}"
          exec npx -y "$PKG" "''${ARGS[@]}"
        elif command -v bun >/dev/null 2>&1; then
          exec bun x "$PKG" "''${ARGS[@]}"
        else
          echo "agent-playwright-mcp: need one of pnpm, npx, or bun on PATH" >&2
          exit 127
        fi
      '';
    };

    ".local/bin/agent-playwright" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Starts (or verifies) the Playwright run-server for agents.
        # Note: keep VERSION in sync with assets/agent-environment/SKILL.md.
        set -euo pipefail
        PORT=3000
        VERSION=1.63.0
        if curl -sf "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
          echo "playwright run-server already running on :$PORT"
          exit 0
        fi
        LOG="''${TMPDIR:-/tmp}/agent-playwright.log"
        # Browser builds are installed per Playwright version; ensure they exist
        # (e.g. after bumping VERSION) before starting the server.
        echo "ensuring playwright@$VERSION browsers are installed..." >&2
        npx -y "playwright@$VERSION" install chromium firefox webkit >/dev/null 2>&1
        nohup npx -y "playwright@$VERSION" run-server --port "$PORT" --host 127.0.0.1 >"$LOG" 2>&1 &
        echo "starting playwright@$VERSION run-server (log: $LOG)..." >&2
        for _ in $(seq 1 60); do
          curl -sf "http://127.0.0.1:$PORT/" >/dev/null 2>&1 && {
            echo "playwright run-server ready on ws://127.0.0.1:$PORT/"
            exit 0
          }
          sleep 1
        done
        echo "run-server did not come up within 60s; see $LOG" >&2
        exit 1
      '';
    };
  };
}
