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
{
  home.file = {
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
