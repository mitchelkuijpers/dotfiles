{pkgs, ...}: {
  programs.fish = {
    enable = true;

    functions.refresh-env = {
      description = "Reload Home Manager session variables";
      # Clear the inherited guard before replacing this shell, not Herdr.
      body = ''
        set -e __HM_SESS_VARS_SOURCED
        exec fish
      '';
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
    '';
  };
}
