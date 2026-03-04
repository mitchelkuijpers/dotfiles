_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings

      # Keep Nix profile paths in front so Nix-installed tools win over system ones.
      fish_add_path --prepend --move ~/.nix-profile/bin /etc/profiles/per-user/$USER/bin

      # pi wrapper: isolate npm global installs to a writable user directory.
      function pi --wraps pi --description "Run pi with isolated npm global prefix"
        set -l pi_npm_prefix "$HOME/.pi/npm-global"
        mkdir -p "$pi_npm_prefix"
        env NPM_CONFIG_PREFIX="$pi_npm_prefix" command pi $argv
      end
    '';
  };
}
