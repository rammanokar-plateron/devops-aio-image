#!/usr/bin/env bash
set -euo pipefail

TARGETARCH="${1:-amd64}"
TOOL_REFRESH_TS="${2:-static}"

# shellcheck disable=SC2034
CACHE_BUSTER="$TOOL_REFRESH_TS"

case "$TARGETARCH" in
  amd64)
    ARCH_K8S="amd64"
    ARCH_YQ="amd64"
    ARCH_TOFU="amd64"
    ARCH_AWS="x86_64"
    ARCH_MONGOSH="x64"
    ;;
  arm64)
    ARCH_K8S="arm64"
    ARCH_YQ="arm64"
    ARCH_TOFU="arm64"
    ARCH_AWS="aarch64"
    ARCH_MONGOSH="arm64"
    ;;
  *)
    echo "Unsupported TARGETARCH: $TARGETARCH" >&2
    exit 1
    ;;
esac

get_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name'
}

# kubectl (latest stable)
KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH_K8S}/kubectl"
chmod +x /usr/local/bin/kubectl

# yq (latest release)
YQ_VERSION="$(get_latest_tag mikefarah/yq)"
curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH_YQ}"
chmod +x /usr/local/bin/yq

# OpenTofu (latest release)
TOFU_VERSION="$(get_latest_tag opentofu/opentofu)"
TOFU_NUM="${TOFU_VERSION#v}"
curl -fsSLo /tmp/tofu.zip "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/tofu_${TOFU_NUM}_linux_${ARCH_TOFU}.zip"
unzip -q /tmp/tofu.zip -d /tmp/tofu
install -m 0755 /tmp/tofu/tofu /usr/local/bin/tofu
rm -rf /tmp/tofu.zip /tmp/tofu

# AWS CLI v2 (latest)
curl -fsSLo /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_AWS}.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# mongosh (latest release asset)
MONGOSH_JSON="$(curl -fsSL https://api.github.com/repos/mongodb-js/mongosh/releases/latest)"
MONGOSH_URL="$(jq -r --arg arch "$ARCH_MONGOSH" '.assets[] | select(.name | test("linux-" + $arch + "\\.tgz$")) | .browser_download_url' <<<"$MONGOSH_JSON" | head -n1)"
if [[ -z "$MONGOSH_URL" ]]; then
  echo "Could not find mongosh tarball for arch: $ARCH_MONGOSH" >&2
  exit 1
fi
curl -fsSLo /tmp/mongosh.tgz "$MONGOSH_URL"
tar -xzf /tmp/mongosh.tgz -C /tmp
MONGOSH_BIN="$(find /tmp -type f -path '*/bin/mongosh' | head -n1)"
install -m 0755 "$MONGOSH_BIN" /usr/local/bin/mongosh
rm -rf /tmp/mongosh.tgz /tmp/mongosh-*

# quick sanity checks at build time
python --version
aws --version
gcloud --version | head -n1
tofu --version
psql --version
mongosh --version
jq --version
yq --version
kubectl version --client=true
