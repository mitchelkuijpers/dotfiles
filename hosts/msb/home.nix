# Home Manager entry for the local agent sandbox image (microsandbox.dev),
# baked into an OCI image by images/agent-image.nix
# (packages.aarch64-linux.agent-image). Ubuntu/exe.dev VMs instead use
# hosts/exedev — see plans/agent-vms.md.
#
# Differences from hosts/exedev:
#   - No targets.genericLinux: the image rootfs is pure /nix/store (there is
#     no FHS distro to integrate into); PATH/shell wiring is done by the image.
#   - ~/.pi/agent/auth.json and models.json stay unmanaged: there is no proxy
#     endpoint here, so pi can persist /login and provider changes made inside
#     the sandbox.
{...}: {
  imports = [
    ../../profiles/agent.nix
  ];

  home = {
    username = "agent";
    homeDirectory = "/home/agent";
    stateVersion = "24.11";
  };
}
