# syntax=docker/dockerfile:1.7
FROM python:3.14-slim

ARG TARGETARCH

# Pinned tool versions (updated via automated PR workflow)
ARG KUBECTL_VERSION=v1.35.2
ARG YQ_VERSION=v4.52.4
ARG TOFU_VERSION=v1.11.5
ARG AWSCLI_VERSION=2.34.4

ENV DEBIAN_FRONTEND=noninteractive

# Keep shell strict so download/install failures fail the build.
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
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

# Google Cloud CLI via signed apt repo.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Mongo Shell via signed MongoDB apt repo.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    curl -fsSL https://pgp.mongodb.com/server-8.0.asc \
      | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" \
      > /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/install-devops-tools.sh /usr/local/bin/install-devops-tools.sh
RUN chmod +x /usr/local/bin/install-devops-tools.sh \
    && /usr/local/bin/install-devops-tools.sh \
      "$TARGETARCH" \
      "$KUBECTL_VERSION" \
      "$YQ_VERSION" \
      "$TOFU_VERSION" \
      "$AWSCLI_VERSION" \
    && rm -f /usr/local/bin/install-devops-tools.sh

# Non-root runtime user for safer default container execution.
RUN groupadd --system --gid 10001 devops \
    && useradd --system --uid 10001 --gid devops --home-dir /home/devops --create-home devops

USER 10001:10001
WORKDIR /home/devops

CMD ["bash"]
