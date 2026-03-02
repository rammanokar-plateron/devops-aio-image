#!/usr/bin/env bash
set -euo pipefail

DOCKERFILE="Dockerfile"

latest_kubectl="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
latest_yq="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')"
latest_tofu="$(curl -fsSL https://api.github.com/repos/opentofu/opentofu/releases/latest | jq -r '.tag_name')"
latest_aws="$(curl -fsSL https://api.github.com/repos/aws/aws-cli/tags | jq -r '.[0].name' | sed 's/^\(2\..*\)$/\1/')"

if [[ -z "$latest_kubectl" || -z "$latest_yq" || -z "$latest_tofu" || -z "$latest_aws" ]]; then
  echo "Failed to resolve latest versions" >&2
  exit 1
fi

sed -i -E "s/^ARG KUBECTL_VERSION=.*/ARG KUBECTL_VERSION=${latest_kubectl}/" "$DOCKERFILE"
sed -i -E "s/^ARG YQ_VERSION=.*/ARG YQ_VERSION=${latest_yq}/" "$DOCKERFILE"
sed -i -E "s/^ARG TOFU_VERSION=.*/ARG TOFU_VERSION=${latest_tofu}/" "$DOCKERFILE"
sed -i -E "s/^ARG AWSCLI_VERSION=.*/ARG AWSCLI_VERSION=${latest_aws}/" "$DOCKERFILE"

echo "Updated tool versions in ${DOCKERFILE}:"
grep -E '^ARG (KUBECTL_VERSION|YQ_VERSION|TOFU_VERSION|AWSCLI_VERSION)=' "$DOCKERFILE"
