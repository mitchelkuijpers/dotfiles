# Home Manager entry for agent VMs on exe.dev (and other Ubuntu VMs where the
# login user is `exedev`). No secrets, no personal keys — see plans/agent-vms.md.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  piConfigDir = config.programs.pi-coding-agent.configDir;
in {
  imports = [
    ../../profiles/agent.nix
    inputs.rex.homeManagerModules.default
  ];

  # Non-NixOS host (Ubuntu): extra PATH/locale handling for nix-installed
  # binaries on a glibc distro that doesn't share NixOS's profile layout.
  targets.genericLinux.enable = true;
  # Headless VM: skip the mesa/llvm GPU driver bundle (~1 GB) that
  # genericLinux pulls in by default for graphics apps.
  targets.genericLinux.gpu.enable = false;

  programs.pi-coding-agent.mutableSettings = true;

  services.rex.enable = true;
  # Keep existing SSH config under the user's control.
  programs.rex.sshGuard = false;

  home = {
    # Keep the direct Synthetic provider available while Magpie manages its own
    # provider entry in the same writable models.json.
    activation.piSyntheticProvider = lib.hm.dag.entryAfter ["linkGeneration"] (
      lib.hm.generators.mkImpureConfigMerger {
        inherit pkgs;
        format = "json";
        empty = "{}";
        mode = "600";
        path = "${piConfigDir}/models.json";
        staticSettings = (pkgs.formats.json {}).generate "pi-synthetic-provider.json" {
          providers.synthetic.baseUrl = "https://synthetic-v2.int.exe.xyz/openai/v1";
        };
        jqOperation = "$dynamic * $static";
      }
    );

    # Rex's remote connector also searches ~/.local/bin on noninteractive SSH.
    file.".local/bin/rex".source = "${config.programs.rex.package}/bin/rex";

    # Only a bogus proxy key: safe to store publicly in Nix. This replaces
    # existing VM credentials; Pi cannot persist /login changes to this file.
    file."${piConfigDir}/auth.json" = {
      text = builtins.toJSON {
        synthetic = {
          type = "api_key";
          key = "syn_randomkey";
        };
      };
      force = true;
    };

    username = "exedev";
    homeDirectory = "/home/exedev";

    # Independent from the Mac's stateVersion; set when this host was added.
    stateVersion = "24.11";
  };
}
