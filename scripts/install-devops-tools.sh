#!/usr/bin/env bash
set -euo pipefail

TARGETARCH="${1:-amd64}"
KUBECTL_VERSION="${2:?KUBECTL_VERSION is required}"
YQ_VERSION="${3:?YQ_VERSION is required}"
TOFU_VERSION="${4:?TOFU_VERSION is required}"
AWSCLI_VERSION="${5:?AWSCLI_VERSION is required}"

case "$TARGETARCH" in
  amd64)
    ARCH_K8S="amd64"
    ARCH_YQ="amd64"
    ARCH_TOFU="amd64"
    ARCH_AWS="x86_64"
    ;;
  arm64)
    ARCH_K8S="arm64"
    ARCH_YQ="arm64"
    ARCH_TOFU="arm64"
    ARCH_AWS="aarch64"
    ;;
  *)
    echo "Unsupported TARGETARCH: $TARGETARCH" >&2
    exit 1
    ;;
esac

verify_sha256_file() {
  local checksum_file="$1"
  local file_path="$2"
  local expected
  expected="$(tr -d '[:space:]' < "$checksum_file")"
  echo "${expected}  ${file_path}" | sha256sum -c -
}

# kubectl (pinned + checksum verification)
curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH_K8S}/kubectl"
curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH_K8S}/kubectl.sha256"
verify_sha256_file /tmp/kubectl.sha256 /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
rm -f /tmp/kubectl.sha256

# yq (pinned + checksum verification)
YQ_ASSET="yq_linux_${ARCH_YQ}"
curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_ASSET}"
curl -fsSLo /tmp/yq_checksums "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums"
awk -v asset="$YQ_ASSET" '$2 == asset {print $1 "  /usr/local/bin/yq"}' /tmp/yq_checksums | sha256sum -c -
chmod +x /usr/local/bin/yq
rm -f /tmp/yq_checksums

# OpenTofu (pinned + checksum verification)
TOFU_NUM="${TOFU_VERSION#v}"
TOFU_ASSET="tofu_${TOFU_NUM}_linux_${ARCH_TOFU}.zip"
curl -fsSLo /tmp/tofu.zip "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/${TOFU_ASSET}"
curl -fsSLo /tmp/tofu_SHA256SUMS "https://github.com/opentofu/opentofu/releases/download/${TOFU_VERSION}/tofu_${TOFU_NUM}_SHA256SUMS"
awk -v asset="$TOFU_ASSET" '$2 == asset {print $1 "  /tmp/tofu.zip"}' /tmp/tofu_SHA256SUMS | sha256sum -c -
unzip -q /tmp/tofu.zip -d /tmp/tofu
install -m 0755 /tmp/tofu/tofu /usr/local/bin/tofu
rm -rf /tmp/tofu.zip /tmp/tofu /tmp/tofu_SHA256SUMS

# AWS CLI v2 (pinned + signature verification)
AWS_FILE="awscliv2.zip"
AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_AWS}-${AWSCLI_VERSION}.zip"
AWS_SIG_URL="${AWS_URL}.sig"

cat >/tmp/aws-cli-public-key.asc <<'AWSCLI_PGP'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF2Cr7UBEADJZHcgusOJl7ENSyumXh85z0TRV0xJorM2B/JL0kHOyigQluUG
ZMLhENaG0bYatdrKP+3H91lvK050pXwnO/R7fB/FSTouki4ciIx5OuLlnJZIxSzx
PqGl0mkxImLNbGWoi6Lto0LYxqHN2iQtzlwTVmq9733zd3XfcXrZ3+LblHAgEt5G
TfNxEKJ8soPLyWmwDH6HWCnjZ/aIQRBTIQ05uVeEoYxSh6wOai7ss/KveoSNBbYz
gbdzoqI2Y8cgH2nbfgp3DSasaLZEdCSsIsK1u05CinE7k2qZ7KgKAUIcT/cR/grk
C6VwsnDU0OUCideXcQ8WeHutqvgZH1JgKDbznoIzeQHJD238GEu+eKhRHcz8/jeG
94zkcgJOz3KbZGYMiTh277Fvj9zzvZsbMBCedV1BTg3TqgvdX4bdkhf5cH+7NtWO
lrFj6UwAsGukBTAOxC0l/dnSmZhJ7Z1KmEWilro/gOrjtOxqRQutlIqG22TaqoPG
fYVN+en3Zwbt97kcgZDwqbuykNt64oZWc4XKCa3mprEGC3IbJTBFqglXmZ7l9ywG
EEUJYOlb2XrSuPWml39beWdKM8kzr1OjnlOm6+lpTRCBfo0wa9F8YZRhHPAkwKkX
XDeOGpWRj4ohOx0d2GWkyV5xyN14p2tQOCdOODmz80yUTgRpPVQUtOEhXQARAQAB
tCFBV1MgQ0xJIFRlYW0gPGF3cy1jbGlAYW1hem9uLmNvbT6JAlQEEwEIAD4CGwMF
CwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQT7Xbd/1cEYuAURraimMQrMRnJHXAUC
aGveYQUJDMpiLAAKCRCmMQrMRnJHXKBYD/9Ab0qQdGiO5hObchG8xh8Rpb4Mjyf6
0JrVo6m8GNjNj6BHkSc8fuTQJ/FaEhaQxj3pjZ3GXPrXjIIVChmICLlFuRXYzrXc
Pw0lniybypsZEVai5kO0tCNBCCFuMN9RsmmRG8mf7lC4FSTbUDmxG/QlYK+0IV/l
uJkzxWa+rySkdpm0JdqumjegNRgObdXHAQDWlubWQHWyZyIQ2B4U7AxqSpcdJp6I
S4Zds4wVLd1WE5pquYQ8vS2cNlDm4QNg8wTj58e3lKN47hXHMIb6CHxRnb947oJa
pg189LLPR5koh+EorNkA1wu5mAJtJvy5YMsppy2y/kIjp3lyY6AmPT1posgGk70Z
CmToEZ5rbd7ARExtlh76A0cabMDFlEHDIK8RNUOSRr7L64+KxOUegKBfQHb9dADY
qqiKqpCbKgvtWlds909Ms74JBgr2KwZCSY1HaOxnIr4CY43QRqAq5YHOay/mU+6w
hhmdF18vpyK0vfkvvGresWtSXbag7Hkt3XjaEw76BzxQH21EBDqU8WJVjHgU6ru+
DJTs+SxgJbaT3hb/vyjlw0lK+hFfhWKRwgOXH8vqducF95NRSUxtS4fpqxWVaw3Q
V2OWSjbne99A5EPEySzryFTKbMGwaTlAwMCwYevt4YT6eb7NmFhTx0Fis4TalUs+
j+c7Kg92pDx2uQ==
=OBAt
-----END PGP PUBLIC KEY BLOCK-----
AWSCLI_PGP

curl -fsSLo "/tmp/${AWS_FILE}" "$AWS_URL"
curl -fsSLo /tmp/awscliv2.sig "$AWS_SIG_URL"
export GNUPGHOME=/tmp/gnupg
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg --batch --import /tmp/aws-cli-public-key.asc
gpg --batch --verify /tmp/awscliv2.sig "/tmp/${AWS_FILE}"
unzip -q "/tmp/${AWS_FILE}" -d /tmp
/tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
rm -rf /tmp/aws "/tmp/${AWS_FILE}" /tmp/awscliv2.sig /tmp/aws-cli-public-key.asc "$GNUPGHOME"

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
