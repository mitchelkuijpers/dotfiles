_: {
  imports = [./fish-shared.nix];

  programs.devenv = {
    enable = true;
    enableFishIntegration = false;
  };
  programs.fish = {
    # Abbreviations expand on Enter, so any shell syntax (env vars, flags) is fine.
    shellAbbrs = {
      # Docker per colima profile: colima registers one Docker context per profile.
      # "colima" is the default profile's context (set active by the colima module);
      # the agent profile's daemon is reachable via its "colima-agent" context.
      dkd = "docker --context colima";
      dka = "docker --context colima-agent";

      # Use the explicit nono-* commands when sandboxing coding agents. OpenCode
      # runs with Bash as its command shell to avoid Fish writing protected
      # config/history paths inside the sandbox.
    };
    interactiveShellInit = ''
      # Was needed for vite plus
      # bass source ~/.zshenv

      # Convenience aliases for local (uncommitted) project flakes.
      alias nd "nix develop path:."
      alias nb "nix build path:."
      alias nr "nix run path:."

      devenv hook fish -- --no-tui | source

      # Testcontainers uses DOCKER_HOST, which is set by the colima module (setDockerHost).
      # See https://java.testcontainers.org/supported_docker_environment/
    '';
  };
}
