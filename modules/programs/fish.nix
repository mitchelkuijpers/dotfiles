{pkgs, ...}: {
  programs.fish = {
    enable = true;

    # Abbreviations expand on Enter, so any shell syntax (env vars, flags) is fine.
    shellAbbrs = {
      # Docker per colima profile: colima registers one Docker context per profile.
      # "colima" is the default profile's context (set active by the colima module);
      # the agent profile's daemon is reachable via its "colima-agent" context.
      dkd = "docker --context colima";
      dka = "docker --context colima-agent";

      # pi inside the nono sandbox (profile pi), e.g. for untrusted worktrees.
      nono-pi = "HERDR_AGENT=pi nono run --profile pi --allow-cwd -- pi";

      # opencode inside the nono sandbox (profile opencode), e.g. for untrusted worktrees.
      nono-opencode = "HERDR_AGENT=opencode nono run --profile opencode --allow-cwd -- opencode";
    };
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z;
      }

      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf;
      }
    ];
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings

      # Keep Nix profile paths in front so Nix-installed tools win over system ones.
      fish_add_path ~/.bin
      fish_add_path --prepend --move ~/.nix-profile/bin /etc/profiles/per-user/$USER/bin

      # Was needed for vite plus
      # bass source ~/.zshenv

      # Convenience aliases for local (uncommitted) project flakes.
      alias nd "nix develop path:."
      alias nb "nix build path:."
      alias nr "nix run path:."


      # Testcontainers uses DOCKER_HOST, which is set by the colima module (setDockerHost).
      # See https://java.testcontainers.org/supported_docker_environment/
    '';
  };
}
