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

      # pi, opencode and maki run inside the nono sandbox by default (untrusted
      # worktrees). Fish does not re-expand abbreviations, so the trailing
      # `pi`/`opencode`/`maki` here resolves to the real binary rather than looping
      # back into this abbreviation. maki runs with `--yolo` (skip permission prompts)
      # because the nono profile already constrains what it can touch.
      pi = "HERDR_AGENT=pi nono run --profile pi --allow-cwd -- pi";
      opencode = "HERDR_AGENT=opencode nono run --profile opencode --allow-cwd -- opencode";
      maki = "HERDR_AGENT=maki nono run --profile maki --allow-cwd -- maki --yolo";

      # Escape hatches: run the real binaries unsandboxed. Abbreviation expansions
      # are not re-scanned, so the trailing `pi`/`opencode`/`maki` here resolves to
      # the real binary. (Typing `command pi` by hand does NOT bypass the `pi`
      # abbreviation.)
      pi-unsafe = "command pi";
      opencode-unsafe = "command opencode";
      maki-unsafe = "command maki";
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
