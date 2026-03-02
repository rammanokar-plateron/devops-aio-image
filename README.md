# devops-aio-image

All-in-one DevOps Docker image published to GHCR with automated dependency and tool version refresh.

## Included tools
- AWS CLI v2 (pinned in Dockerfile, signature-verified)
- Google Cloud CLI (signed apt repository)
- OpenTofu (pinned in Dockerfile, checksum-verified)
- PostgreSQL client (`psql`)
- `mongosh` (signed apt repository)
- Python 3.14
- `jq`
- `yq` (pinned in Dockerfile, checksum-verified)
- `kubectl` (pinned in Dockerfile, checksum-verified)

## Image
- Registry: `ghcr.io/rammanokar-plateron/devops-aio-image`
- Tags produced by CI:
  - `latest` (on `main`)
  - `sha-<commit>`

## Automation
- Build workflow (`build-and-push.yml`):
  - builds and pushes image on every push to `main`
  - uses BuildKit cache + GitHub Actions cache for faster builds
  - generates SBOM and provenance attestations
- Tool refresh workflow (`refresh-tool-versions.yml`):
  - runs daily and opens PR to bump pinned tool versions in `Dockerfile`
- Dependabot:
  - updates GitHub Actions versions
  - updates Docker base image references

## Usage
```bash
docker pull ghcr.io/rammanokar-plateron/devops-aio-image:latest
docker run --rm -it ghcr.io/rammanokar-plateron/devops-aio-image:latest bash
```
