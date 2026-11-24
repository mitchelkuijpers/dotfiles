FROM debian:trixie-slim AS build

ARG TARGETARCH
ARG FISH_VERSION=4.9.3
ARG STARSHIP_VERSION=1.27.0

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates xz-utils

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) fish_arch=x86_64 ;; \
      arm64) fish_arch=aarch64 ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /out; \
    curl -fsSL "https://github.com/fish-shell/fish-shell/releases/download/${FISH_VERSION}/fish-${FISH_VERSION}-linux-${fish_arch}.tar.xz" \
      | tar -xJ -C /out;

FROM scratch

COPY --from=build /out/fish /usr/local/bin/fish
