{
  config,
  pkgs,
  lib,
  ...
}: let
  # SSH signing is Mac-only: agent VMs deliberately get no personal keys.
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  signingKey = "${config.home.homeDirectory}/.ssh/avisi.pub";
  allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
  email = "mitchel.kuijpers@avisi.nl";
in {
  programs.git = {
    enable = true;

    settings = {
      user.name = "Mitchel Kuijpers";
      user.email = email;
      push.autoSetupRemote = true;
      gpg = {
        format = lib.mkIf isDarwin "ssh";
        # Git only needs this for verification (git log --show-signature, %G?).
        "ssh".allowedSignersFile = lib.mkIf isDarwin allowedSignersFile;
      };
    };

    signing = lib.mkIf isDarwin {
      key = signingKey;
      signByDefault = true;
    };

    ignores = [
      ".DS_Store"
      ".lsp/"
      ".sidecar/"
    ];
  };

  # Derive the allowed-signers file from the machine's actual local key instead
  # of checking in a machine-specific public key. Keeps the config portable
  # across Macs while still pointing git at a stable XDG path.
  home.activation.gitAllowedSigners = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      key=${lib.escapeShellArg signingKey}
      if [ -f "$key" ]; then
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf allowedSignersFile)}
        ${pkgs.coreutils}/bin/printf '%s %s\n' ${lib.escapeShellArg email} "$(${pkgs.coreutils}/bin/cat "$key")" > ${lib.escapeShellArg allowedSignersFile}
      fi
    ''
  );
}
