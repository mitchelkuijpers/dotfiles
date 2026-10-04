# Home Manager entry for agent VMs on exe.dev (and other Ubuntu VMs where the
# login user is `exedev`). No secrets, no personal keys — see plans/agent-vms.md.
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../profiles/agent.nix
  ];

  # Non-NixOS host (Ubuntu): extra PATH/locale handling for nix-installed
  # binaries on a glibc distro that doesn't share NixOS's profile layout.
  targets.genericLinux.enable = true;
  # Headless VM: skip the mesa/llvm GPU driver bundle (~1 GB) that
  # genericLinux pulls in by default for graphics apps.
  targets.genericLinux.gpu.enable = false;

  # exe.dev's integration proxies Synthetic model requests; leave the Mac and
  # shellbox on their own endpoints. Pi's provider extension supplies models.
  home = {
    file."${config.programs.pi-coding-agent.configDir}/models.json".text = builtins.toJSON {
      providers.synthetic.baseUrl = "https://synthetic-v2.int.exe.xyz/openai/v1";
    };

    # Pi owns auth.json and may add real credentials later. Seed only the dummy
    # proxy credential, preserving any existing credentials and keeping the file
    # writable and private instead of symlinking it into the public Nix store.
    activation.seedSyntheticProxyAuth = lib.hm.dag.entryAfter ["writeBoundary"] ''
      authFile="${config.programs.pi-coding-agent.configDir}/auth.json"
      if [ -n "''${DRY_RUN+x}" ]; then
        echo "Would ensure Synthetic proxy credential in $authFile"
      else
        (
          umask 077
          mkdir -p "$(dirname "$authFile")"
          if [ -L "$authFile" ]; then
            echo "Refusing to replace symlinked Pi auth file: $authFile" >&2
            exit 1
          elif [ ! -e "$authFile" ]; then
            printf '%s\n' '{"synthetic":{"type":"api_key","key":"syn_randomkey"}}' > "$authFile"
          elif ! ${pkgs.jq}/bin/jq -e 'has("synthetic")' "$authFile" >/dev/null; then
            tmpFile=$(${pkgs.coreutils}/bin/mktemp "$authFile.XXXXXX")
            trap 'rm -f "$tmpFile"' EXIT
            ${pkgs.jq}/bin/jq '.synthetic = {type: "api_key", key: "syn_randomkey"}' "$authFile" > "$tmpFile"
            mv "$tmpFile" "$authFile"
          fi
        )
      fi
    '';

    username = "exedev";
    homeDirectory = "/home/exedev";

    # Independent from the Mac's stateVersion; set when this host was added.
    stateVersion = "24.11";
  };
}
