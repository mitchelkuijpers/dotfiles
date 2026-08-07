{pkgs, ...}: {
  programs.fish = {
    enable = true;
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
