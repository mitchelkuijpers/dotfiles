# OCI image of the agent toolchain for local sandboxes (microsandbox.dev),
# built from homeConfigurations.msb (hosts/msb/home.nix + profiles/agent.nix).
# The exe.dev/Ubuntu VM story lives in hosts/exedev + plans/agent-vms.md.
#
# The rootfs is pure Nix: no distro layer, no systemd (microsandbox's guest
# agent is PID 1), no package manager. dockerTools.buildLayeredImage packs the
# Home Manager activation closure into /nix/store layers (with the Nix
# database, so `nix` works inside the sandbox — microsandbox roots are
# writable overlayfs), and fakeRootCommands wire up /etc wiring that gives the
# sandbox exeuntu-like ergonomics: an unprivileged `agent` user with
# passwordless sudo.
#
# Home Manager activates at first boot from the ENTRYPOINT (idempotent), into
# the writable root — no daemon, no bootstrap script.
#
# Build/load/run (see `make image`):
#   nix build .#agent-image -o agent-image.tar
#   msb load --input agent-image.tar --tag agent:local
#   msb run agent:local          # attached: lands in fish as `agent`
{
  pkgs,
  activationPackage,
  username ? "agent",
  uid ? 1000,
}: let
  lib = pkgs.lib;
  homeDir = "/home/${username}";
  hmProfile = "${homeDir}/.nix-profile";

  # Must live at a fixed absolute path inside the image, hence also in
  # `imageRoot` below.
  entrypoint = pkgs.writeShellScriptBin "agent-entry" ''
    set -euo pipefail

    # microsandbox's guest agent runs image workloads as root by default;
    # re-exec as the unprivileged agent user so everything lands under
    # /home/agent with the right ownership. Before dropping privileges: the
    # Home Manager activation installs the profile with nix-env, which builds
    # the user environment *in the store* — make it writable (sticky, like
    # NixOS's root:trusted 1733, but also readable: there is no daemon here,
    # nix runs unprivileged against the local store) through this sandbox's
    # writable root.
    if [ "$(id -u)" -eq 0 ]; then
      chmod 1777 /nix/store 2>/dev/null || true
      exec ${pkgs.util-linux}/bin/setpriv \
        --reuid=${username} --regid=${username} --init-groups --inh-caps=-all \
        env USER=${username} LOGNAME=${username} "$0" "$@"
    fi

    # First-boot Home Manager activation (idempotent: a no-op once
    # ~/.nix-profile exists). Home Manager's setupVars requires
    # ~/.local/state/nix/profiles to exist, and the activation script needs
    # `nix` (sanity check + profile install) and `jq` on PATH. The profile
    # install is a daemonless unprivileged build, so the Nix sandbox must be
    # off (no user namespaces in some runtimes).
    if [ ! -e "${hmProfile}" ]; then
      mkdir -p "$HOME/.local/state/nix/profiles"
      export PATH="${pkgs.nix}/bin:${pkgs.jq}/bin:$PATH"
      NIX_CONFIG="sandbox = false" ${activationPackage}/activate
    fi

    exec "$@"
  '';

  # Everything the image needs; buildLayeredImage puts the closure of these
  # into /nix/store layers and merges their trees (bin/, etc/, lib/) into the
  # customisation layer at the image root.
  imageRoot = pkgs.buildEnv {
    name = "agent-image-root";
    paths = [
      activationPackage
      entrypoint
      pkgs.bashInteractive # /bin/bash + sh for the guest agent's shell()/exec()
      pkgs.cacert # CA bundle: referenced by /etc/ssl/certs and SSL_CERT_FILE below
      pkgs.coreutils # /usr/bin/env for #!/usr/bin/env shebangs in store scripts
      pkgs.jq # used by the Home Manager activation script
      pkgs.nix # needed by activation; also makes `nix` usable inside
      pkgs.pam # PAM modules, referenced by absolute path from /etc/pam.d/sudo
      pkgs.sudo
      pkgs.util-linux # setpriv (drop to the agent user)
    ];
  };
in
  pkgs.dockerTools.buildLayeredImage {
    name = "agent";
    tag = "local";
    # Uncompressed: msb load takes OCI/docker archives, and layer sharing
    # already happens via the store layers, not the outer tar.
    compressor = "none";
    contents = [imageRoot];
    # Populate nix/var/nix/db from the closure so `nix`/activation work inside
    # the sandbox without a daemon or channel.
    includeNixDB = true;

    config = {
      User = username;
      WorkingDir = homeDir;
      Env = [
        "HOME=${homeDir}"
        "USER=${username}"
        "PATH=${hmProfile}/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      Entrypoint = ["${entrypoint}/bin/agent-entry"];
      # fish comes via the Home Manager profile (profiles/base.nix).
      Cmd = ["${pkgs.fish}/bin/fish"];
    };

    # Run inside the customisation layer (relative paths); fakeroot records
    # ownership and setuid bits into the layer tar.
    fakeRootCommands = with pkgs; ''
      # --- user database (glibc NSS "files") --------------------------------
      # NOTE: fakeRootCommands run with cwd = the layer rootfs (fakeroot, not
      # chrooted), so all paths here must be RELATIVE; absolute ones would
      # escape into the build sandbox.
      mkdir -p etc etc/pam.d etc/sudoers.d usr/bin bin home/agent root tmp
      # Sticky world-writable, as on any distro: the HM activation's nix-build
      # sanity check needs a writable TMPDIR.
      chmod 1777 tmp
      # The activation runs as the unprivileged agent user against the local
      # (daemonless) store, so all Nix state populated by includeNixDB must be
      # owned by it: nix creates/chowns per-user profiles + gcroots dirs,
      # needs db locks and writes build logs under nix/var/log. Root (sudo)
      # ignores ownership anyway.
      mkdir -p nix/var/log/nix/drvs
      chown -R ${toString uid}:${toString uid} nix/var
      chown ${toString uid}:${toString uid} home/agent

      # BuildEnv merges the packages' own /etc files into the layer as
      # read-only store symlinks; replace the ones we own with real files.
      rm -f etc/passwd etc/group etc/shadow etc/nsswitch.conf etc/hosts etc/sudoers etc/sudoers.dist etc/pam.d/sudo
      cat > etc/passwd <<EOF
      root:x:0:0:root:/root:/bin/bash
      ${username}:x:${toString uid}:${toString uid}:Agent:/home/${username}:/bin/bash
      EOF
      cat > etc/group <<EOF
      root:x:0:
      ${username}:x:${toString uid}:
      EOF
      cat > etc/shadow <<EOF
      root:!:19000::::::
      ${username}:!:19000::::::
      EOF
      chmod 0000 etc/shadow
      cat > etc/nsswitch.conf <<EOF
      passwd: files
      group: files
      shadow: files
      hosts: files dns
      EOF
      echo "127.0.0.1 localhost" > etc/hosts

      # --- shells and env ---------------------------------------------------
      # /bin/bash and /bin/sh are merged into the layer already by imageRoot;
      # pin them to the interactive bash and add /bin/sh + /usr/bin/env so the
      # guest agent's shell()/exec() and #!/usr/bin/env store scripts work.
      ln -sfn ${lib.getExe pkgs.bashInteractive} bin/bash
      ln -sfn bash bin/sh
      ln -sfn ${lib.getExe pkgs.coreutils} usr/bin/env

      # --- passwordless sudo (exeuntu parity) --------------------------------
      # A setuid copy outside the read-only store: store paths cannot carry
      # setuid bits, so sudo must be re-installed into the writable layer.
      # Config and PAM are wired to /etc; plugins stay at the compiled-in
      # store path. NOPASSWD skips PAM's auth phase entirely, so a
      # permit-only stack suffices (no shadow/NSS dependencies).
      install -Dm4755 -o0 -g0 ${lib.getExe pkgs.sudo} usr/bin/sudo
      install -Dm4755 -o0 -g0 ${pkgs.sudo}/bin/sudoedit usr/bin/sudoedit
      cat > etc/sudoers <<EOF
      root ALL=(ALL:ALL) NOPASSWD: ALL
      ${username} ALL=(ALL:ALL) NOPASSWD: ALL
      Defaults !lecture
      Defaults env_keep += "PATH HOME TERM LANG NIX_PATH"
      EOF
      chmod 0440 etc/sudoers
      cat > etc/pam.d/sudo <<EOF
      #%PAM-1.0
      auth sufficient ${pkgs.pam}/lib/security/pam_permit.so
      account sufficient ${pkgs.pam}/lib/security/pam_permit.so
      session sufficient ${pkgs.pam}/lib/security/pam_permit.so
      EOF

      # /etc/ssl/certs/ca-bundle.crt is merged into the layer by imageRoot
      # (cacert ships it); SSL_CERT_FILE in the image config points there too.
    '';
  }
