FROM debian:trixie-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates
RUN curl -fsSL https://mise.run | sh

FROM scratch

COPY --from=build /root/.local/bin/mise /usr/local/bin/
