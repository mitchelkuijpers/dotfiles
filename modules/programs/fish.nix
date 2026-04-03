_: {
  programs.fish = {
    enable = true;
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
    '';
  };
}
