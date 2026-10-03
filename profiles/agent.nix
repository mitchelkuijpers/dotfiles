# Profile for agent VMs (Ubuntu, Linux): same shell/editor/git/CLI tooling as
# the Mac dev profile, minus macOS-only modules (colima, agent-environment,
# herdr workflow) and anything needing personal secrets or keys.
_: {
  imports = [
    ./base.nix

    ../modules/common/packages.nix
    # Platform-appropriate agent-environment skill (the Mac variant lives in
    # modules/common/agent-environment.nix, imported only via profiles/dev.nix).
    ../modules/common/agent-vm-skill.nix

    ../modules/programs/mise.nix
    ../modules/programs/direnv.nix
    ../modules/programs/fzf.nix
    ../modules/programs/starship.nix
    ../modules/programs/pi.nix
  ];
}
