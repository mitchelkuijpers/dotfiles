FROM nixos/nix:2.34.7 AS build

ARG TARGETARCH
COPY config/ /config/

RUN set -eu; \
    case "$TARGETARCH" in \
      arm64) home=docker-sandbox-arm ;; \
      amd64) home=docker-sandbox ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    nix --extra-experimental-features 'nix-command flakes' build \
      --accept-flake-config --option sandbox false --no-update-lock-file --out-link /tmp/sandbox-home \
      "path:/config#homeConfigurations.$home.activationPackage"; \
    mkdir -p /out/nix/store /out/opt/docker-sandbox-home /out/usr/local/bin; \
    for output in home-files home-path; do \
      path="$(readlink "/tmp/sandbox-home/$output")"; \
      ln -s "$path" "/out/opt/docker-sandbox-home/$output"; \
      nix-store --query --requisites "$path" >> /tmp/runtime-paths; \
    done; \
    sort -u /tmp/runtime-paths | xargs cp -a -t /out/nix/store; \
    printf '%s\n' '#!/bin/sh' 'export PATH="/home/agent/.nix-profile/bin:$PATH"' \
      'exec /opt/docker-sandbox-home/home-path/bin/fish "$@"' > /out/usr/local/bin/fish; \
    chmod 0755 /out/usr/local/bin/fish

FROM scratch
COPY --from=build /out/ /
