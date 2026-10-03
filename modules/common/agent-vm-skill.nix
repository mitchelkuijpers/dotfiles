# Linux-VM counterpart to modules/common/agent-environment.nix.
#
# On a Linux agent VM there is no sandbox and no host Chrome / colima to
# attach to, so the Mac skill would be actively wrong. This links a
# platform-appropriate skill under the same `agent-environment` name into
# ~/.agents/skills, which pi, opencode and other compliant agents discover
# natively.
#
# Guarded to Linux: on macOS the Mac module owns this skill name.
{
  lib,
  pkgs,
  ...
}: {
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    ".agents/skills/agent-environment/SKILL.md".source = ../../assets/agent-vm/SKILL.md;
  };
}
