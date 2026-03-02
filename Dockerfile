FROM python:3.14-slim

ARG TARGETARCH
ARG TOOL_REFRESH_TS=static
ENV DEBIAN_FRONTEND=noninteractive

# Keep shell strict so download/install failures fail the build.
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      unzip \
      tar \
      gzip \
      jq \
      git \
      less \
      bash \
      postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/install-devops-tools.sh /usr/local/bin/install-devops-tools.sh
RUN chmod +x /usr/local/bin/install-devops-tools.sh \
    && /usr/local/bin/install-devops-tools.sh "$TARGETARCH" "$TOOL_REFRESH_TS" \
    && rm -f /usr/local/bin/install-devops-tools.sh

CMD ["bash"]
