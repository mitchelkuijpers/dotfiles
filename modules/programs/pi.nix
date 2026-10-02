{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  jsonFormat = pkgs.formats.json {};
in {
  programs.pi-coding-agent = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

    # Written to ~/.pi/agent/settings.json.
    # Note: pi mutates this file at runtime (selected model, changelog state, etc.).
    # Switching resets it to exactly this set — re-add runtime-only keys here if needed.
    settings = {
      # Synthetic DeepSeek as default (requested override).
      defaultProvider = "synthetic";
      defaultModel = "hf:deepseek-ai/DeepSeek-V4.1-Flash";
      defaultThinkingLevel = "high";
      hideThinkingBlock = false;
      npmCommand = [
        "pnpm"
        "--ignore-scripts"
      ];
      packages =
        [
          "npm:@ujjwalgrover/pi-catppuccin"
          "npm:pi-openspec-status"
          "npm:@aliou/pi-synthetic"
          "npm:pi-blackhole"
          # "npm:pi-browser-use@0.11.7"
          # "/Users/mitkuijp/Development/pi-bert"
          "git:github.com/NVlabs/SoL-Pi"
        ]
        # nono's pi package is only provisioned on the Mac.
        ++ lib.optionals pkgs.stdenv.isDarwin [
          {
            source = "/Users/mitkuijp/.config/nono/packages/nolabs-ai/pi";
          }
        ];
      editorPaddingX = 1;
      transport = "websocket";
      permissionLevel = "medium";
      terminal = {
        showTerminalProgress = true;
      };
      collapseChangelog = true;
      modelThinkingLevels = {
        "openai-codex/gpt-5.6-sol" = "high";
        "synthetic/hf:moonshotai/Kimi-K3" = "high";
        "openai-codex/gpt-5.6-luna" = "xhigh";
      };
      enabledModels = [
        "synthetic/hf:zai-org/GLM-5.3-Flash"
        "synthetic/hf:deepseek-ai/DeepSeek-V4.1-Flash"
        "synthetic/hf:moonshotai/Kimi-K3"
        "openai-codex/gpt-6-luna"
        "openai-codex/gpt-6-sol"
      ];
    };
  };

  # MCP servers. Home Manager has no dedicated option for these yet, so write
  # <configDir>/mcp.json directly.
  #
  # The Playwright MCP server drives the host agent Chrome over CDP (started by
  # `agent-browser`, see modules/common/agent-environment.nix) instead of
  # launching its own browser — the nono sandbox forbids launching browsers.
  # The launcher is `agent-playwright-mcp`, which picks pnpm/npx/bun and keeps
  # install output off stdout so it can't corrupt the JSON-RPC stream.
  # `codemode` exposure keeps the 25 browser tools out of the tool list; call
  # them from a codemode script instead. macOS-only (host Chrome).
  home.file."${cfg.configDir}/mcp.json" = lib.mkIf pkgs.stdenv.isDarwin {
    source = jsonFormat.generate "pi-mcp.json" {
      mcpServers.playwright = {
        command = "agent-playwright-mcp";
        exposure = "codemode";
        description = "Drive the user's running agent Chrome browser over CDP (127.0.0.1:13306): navigate, snapshot, click, type, screenshot, read console/network";
      };
    };
  };
}
