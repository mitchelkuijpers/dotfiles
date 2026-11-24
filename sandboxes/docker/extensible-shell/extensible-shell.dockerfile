FROM docker.io/sbx/shell-docker-image:latest

RUN printf '#!/usr/bin/env bash\nbash -l\n' > /home/agent/entrypoint.sh && \
    chmod 0700 /home/agent/entrypoint.sh

ENTRYPOINT ["/home/agent/entrypoint.sh"]
