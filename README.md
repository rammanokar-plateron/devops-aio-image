# devops-aio-image

All-in-one DevOps Docker image published to GHCR with automated daily rebuilds and dependency updates.

## Included tools
- AWS CLI v2 (latest at build time)
- Google Cloud CLI (latest apt package)
- OpenTofu (latest GitHub release)
- PostgreSQL client (`psql`)
- `mongosh` (latest GitHub release)
- Python 3.14
- `jq`
- `yq` (latest GitHub release)
- `kubectl` (latest stable)

## Image
- Registry: `ghcr.io/rammanokar-plateron/devops-aio-image`
- Tags produced by CI:
  - `latest` (on `main`)
  - `sha-<commit>`
  - daily schedule tag (`YYYYMMDD`)

## Automation
- GitHub Actions workflow:
  - builds and pushes image on every push to `main`
  - runs daily to rebuild with latest tool versions
- Dependabot:
  - updates GitHub Actions dependencies
  - updates Docker base image reference

## Usage
```bash
docker pull ghcr.io/rammanokar-plateron/devops-aio-image:latest
docker run --rm -it ghcr.io/rammanokar-plateron/devops-aio-image:latest bash
```
