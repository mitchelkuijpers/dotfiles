{
  inputs,
  pkgs,
  ...
}: {
  programs.pi-coding-agent = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

    settings = {
      hideThinkingBlock = false;
      editorPaddingX = 1;
      transport = "websocket";
      permissionLevel = "medium";
      terminal.showTerminalProgress = true;
      collapseChangelog = true;
    };
  };
}
