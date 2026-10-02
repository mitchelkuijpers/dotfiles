# Home Manager entry for agent VMs on exe.dev (and other Ubuntu VMs where the
# login user is `exedev`). No secrets, no personal keys — see plans/agent-vms.md.
_: {
  imports = [
    ../../profiles/agent.nix
  ];

  # Non-NixOS host (Ubuntu): extra PATH/locale handling for nix-installed
  # binaries on a glibc distro that doesn't share NixOS's profile layout.
  targets.genericLinux.enable = true;

  home = {
    username = "exedev";
    homeDirectory = "/home/exedev";

    # Independent from the Mac's stateVersion; set when this host was added.
    stateVersion = "24.11";
  };
}
