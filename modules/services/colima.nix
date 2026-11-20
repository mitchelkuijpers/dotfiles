{
  pkgs,
  config,
  ...
}: let
  useVzRosetta = pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
  colimaVmType =
    if useVzRosetta
    then "vz"
    else "qemu";

  # The stock fstrim service only reads /etc/fstab when it exists, which
  # omits Colima's separately mounted Docker data disk. Trim all local
  # filesystems daily so deleted Docker data releases host disk space.
  trimProvision = [
    {
      mode = "system";
      script = ''
        set -eu
        mkdir -p /etc/systemd/system/fstrim.service.d /etc/systemd/system/fstrim.timer.d
        cat > /etc/systemd/system/fstrim.service.d/colima.conf <<'EOF'
        [Unit]
        Description=Discard unused blocks on all mounted local filesystems

        [Service]
        ExecStart=
        ExecStart=/sbin/fstrim --all --verbose --quiet-unsupported
        EOF
        cat > /etc/systemd/system/fstrim.timer.d/colima.conf <<'EOF'
        [Unit]
        Description=Discard unused filesystem blocks daily

        [Timer]
        OnCalendar=
        OnCalendar=daily
        EOF
        systemctl daemon-reload
        systemctl enable fstrim.timer
        systemctl restart fstrim.timer
      '';
    }
  ];
in {
  # Helpers for the launchd-managed colima profiles below. Plain scripts (not
  # fish functions) so both humans and agents can run them from any shell.
  home.file = {
    ".local/bin/crestart" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Bounce a launchd-managed colima profile (default: agent).
        set -euo pipefail
        profile="''${1:-agent}"
        exec launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.colima-$profile"
      '';
    };

    ".local/bin/crecreate" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Recreate a launchd-managed colima profile VM from its config.
        # Guards against colima's config-wiping delete: stashes colima.yaml
        # so launchd doesn't restart the VM with factory defaults.
        set -euo pipefail
        profile="''${1:-agent}"
        cfg="$HOME/.colima/$profile/colima.yaml"
        if [ ! -s "$cfg" ]; then
          echo "refusing: $cfg missing/empty - run 'make switch' first to regenerate it" >&2
          exit 1
        fi
        stash="$(mktemp)"
        cp "$cfg" "$stash"
        colima delete "$profile"
        mkdir -p "$(dirname "$cfg")"
        cp "$stash" "$cfg"
        rm -f "$stash"
        launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.colima-$profile"
        echo "recreating colima-$profile (watch: clogs $profile)"
      '';
    };

    ".local/bin/clogs" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Tail the service log of a launchd-managed colima profile.
        set -euo pipefail
        profile="''${1:-agent}"
        exec tail -f "$HOME/.local/state/colima/$profile.log"
      '';
    };
  };

  services.colima = {
    enable = true;
    package = pkgs.colima;

    profiles = {
      default = {
        isService = true;
        isActive = true;
        setDockerHost = true;

        settings = {
          runtime = "docker";
          provision = trimProvision;
          cpu = 12;
          disk = 40;
          memory = 8;
          arch = "host";
          vmType = colimaVmType;
          rosetta = useVzRosetta;
          network = {
            address = true;
          };

          mounts = [
            {
              location = config.home.homeDirectory;
              writable = true;
            }
          ];
        };
      };

      agent = {
        isService = true;

        # Important: leave both of these false.
        isActive = false;
        setDockerHost = false;

        settings = {
          runtime = "docker";
          provision = trimProvision;

          cpu = 6;
          disk = 40;
          memory = 8;

          arch = "host";
          vmType = colimaVmType;
          rosetta = useVzRosetta;

          network = {
            address = true;
          };

          # Crucially, don't mount your complete home directory.
          mounts = [
            {
              location = "${config.home.homeDirectory}/Agents";
              writable = true;
            }
            {
              location = "${config.home.homeDirectory}/.herdr/worktrees";
              writable = true;
            }
            {
              location = "${config.home.homeDirectory}/Development/nvbf";
              writable = true;
            }
          ];
        };
      };
    };
  };
}
