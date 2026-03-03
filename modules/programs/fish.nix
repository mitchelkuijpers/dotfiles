{ ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings

      # Keep Nix profile paths in front so Nix-installed tools win over system ones.
      fish_add_path --prepend --move ~/.nix-profile/bin /etc/profiles/per-user/$USER/bin
    '';
  };
}
