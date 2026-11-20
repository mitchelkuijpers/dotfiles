{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  jsonFormat = pkgs.formats.json {};
  modelDefaults = {
    defaultProvider = "synthetic";
    defaultModel = "hf:deepseek-ai/DeepSeek-V4.1-Flash";
    defaultThinkingLevel = "high";
  };
in {
  programs.pi-coding-agent = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

    # Home Manager merges shared settings into a writable file on hosts where
    # Magpie selects the model. Other hosts use the pinned Synthetic default.
    mutableSettings = lib.mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    settings =
      {
        hideThinkingBlock = false;
        npmCommand = [
          "pnpm"
          "--ignore-scripts"
        ];
        packages =
          [
            "npm:pi-openspec-status"
            "npm:@aliou/pi-synthetic"
            "npm:pi-blackhole"
            "npm:@router-for-me/pi-cliproxyapi-provider"
            # "npm:pi-browser-use@0.11.7"
            # "/Users/mitkuijp/Development/pi-bert"
            "git:github.com/NVlabs/SoL-Pi"
          ]
          # nono's pi package is only provisioned on the Mac.
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
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
      }
      # Leave Magpie's model and thinking settings out of the activation merge.
      // lib.optionalAttrs (!cfg.mutableSettings) modelDefaults;
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
  home.file."${cfg.configDir}/mcp.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = jsonFormat.generate "pi-mcp.json" {
      mcpServers.playwright = {
        command = "agent-playwright-mcp";
        exposure = "codemode";
        description = "Drive the user's running agent Chrome browser over CDP (127.0.0.1:13306): navigate, snapshot, click, type, screenshot, read console/network";
      };
    };
  };
}
