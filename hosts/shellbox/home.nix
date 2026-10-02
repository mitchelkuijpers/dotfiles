# Home Manager entry for shellbox.dev boxes (Azure x86_64 Ubuntu VMs).
# shellbox logs you in as root via the box name: ssh <name>@shellbox.dev.
# No secrets, no personal keys — see plans/agent-vms.md.
_: {
  imports = [
    ../../profiles/agent.nix
  ];

  # Non-NixOS host (Ubuntu): extra PATH/locale handling for nix-installed
  # binaries on a glibc distro that doesn't share NixOS's profile layout.
  targets.genericLinux.enable = true;

  home = {
    username = "root";
    homeDirectory = "/root";

    # Independent from the Mac's stateVersion; set when this host was added.
    stateVersion = "24.11";
  };
}
