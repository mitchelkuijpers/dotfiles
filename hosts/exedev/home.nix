# Home Manager entry for agent VMs on exe.dev (and other Ubuntu VMs where the
# login user is `exedev`). No secrets, no personal keys — see plans/agent-vms.md.
{config, ...}: {
  imports = [
    ../../profiles/agent.nix
  ];

  # Non-NixOS host (Ubuntu): extra PATH/locale handling for nix-installed
  # binaries on a glibc distro that doesn't share NixOS's profile layout.
  targets.genericLinux.enable = true;
  # Headless VM: skip the mesa/llvm GPU driver bundle (~1 GB) that
  # genericLinux pulls in by default for graphics apps.
  targets.genericLinux.gpu.enable = false;

  # exe.dev's integration proxies Synthetic model requests; leave the Mac and
  # shellbox on their own endpoints. Pi's provider extension supplies models.
  home = {
    file."${config.programs.pi-coding-agent.configDir}/models.json".text = builtins.toJSON {
      providers.synthetic.baseUrl = "https://synthetic-v2.int.exe.xyz/openai/v1";
    };

    # Only a bogus proxy key: safe to store publicly in Nix. This replaces
    # existing VM credentials; Pi cannot persist /login changes to this file.
    file."${config.programs.pi-coding-agent.configDir}/auth.json" = {
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
