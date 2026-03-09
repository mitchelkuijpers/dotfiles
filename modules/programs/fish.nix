_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings

      # Keep Nix profile paths in front so Nix-installed tools win over system ones.
      fish_add_path ~/.bin
      fish_add_path --prepend --move ~/.nix-profile/bin /etc/profiles/per-user/$USER/bin

      # Convenience aliases for local (uncommitted) project flakes.
      alias nd "nix develop path:."
      alias nb "nix build path:."
      alias nr "nix run path:."
    '';
  };
}
