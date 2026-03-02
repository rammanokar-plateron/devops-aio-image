# AGENTS.md

This file defines how coding agents should work in this repository.

## Mission
Build and maintain a secure, reproducible, and fast-building all-in-one DevOps Docker image published to GHCR.

## Repository Scope
Primary artifacts in this repo:
- `Dockerfile`
- `scripts/install-devops-tools.sh`
- `scripts/update-tool-versions.sh`
- `.github/workflows/build-and-push.yml`
- `.github/workflows/refresh-tool-versions.yml`
- `.github/dependabot.yml`
- `README.md`

## Non-Negotiable Standards
- Keep the image secure by default.
- Keep builds reproducible via pinned versions.
- Keep CI supply chain hardened (pin action SHAs).
- Keep build speed optimized with cache usage.
- Keep runtime non-root unless there is a hard requirement otherwise.

## Dockerfile Rules
- Do not switch to unpinned “latest” for tool binaries.
- Keep tool versions as `ARG` values in `Dockerfile`.
- Verify downloaded binaries with checksums/signatures before install.
- Use BuildKit cache mounts where useful (`apt` caches are already set).
- Avoid unnecessary packages and remove apt lists after install.
- Preserve non-root runtime user (`USER 10001:10001`) unless explicitly required to change.
- Keep architecture handling compatible with both `linux/amd64` and `linux/arm64`.

## Tool Installation Rules
- `scripts/install-devops-tools.sh` is the source of truth for manual binary installs.
- Any new downloaded tool must include integrity verification.
- Prefer official signed apt repositories where available.
- Keep sanity checks at the end of install script so build failures are explicit.

## Version Management Rules
- Pinned versions live in Dockerfile ARGs:
  - `KUBECTL_VERSION`
  - `YQ_VERSION`
  - `TOFU_VERSION`
  - `AWSCLI_VERSION`
- Daily version refresh PRs are created by `.github/workflows/refresh-tool-versions.yml`.
- Dependabot updates:
  - GitHub Actions dependencies
  - Docker base image references
- Do not bypass automated PR flows unless explicitly requested.

## CI/CD Rules
- Build workflow is `.github/workflows/build-and-push.yml`.
- Keep all `uses:` actions pinned by commit SHA.
- Preserve least-privilege permissions in workflows.
- Keep `concurrency` to avoid duplicate parallel runs.
- Keep `cache-from`/`cache-to` enabled for faster builds.
- Keep SBOM/provenance generation enabled unless breaking requirements demand otherwise.

## Tagging and Publishing
- Publish to GHCR: `ghcr.io/<owner>/<repo>`.
- Default tags expected from CI:
  - `latest` (default branch only)
  - `sha-<commit>`

## Change Process for Agents
For every meaningful change:
1. Make the smallest safe edit.
2. Verify file consistency and references.
3. Run lightweight checks when possible (shell syntax, YAML sanity, etc.).
4. Update `README.md` if behavior, tools, or workflows changed.
5. Summarize risk and impact in the final response.

## Review Checklist (Before Finishing)
- Security:
  - Are all downloads verified?
  - Are workflow actions SHA-pinned?
- Reproducibility:
  - Are versions pinned and not silently floating?
- Performance:
  - Is build caching preserved?
- Runtime safety:
  - Is non-root user preserved?
- Automation:
  - Do Dependabot and refresh workflow still function?

## What Not To Do
- Do not remove checksum/signature verification.
- Do not replace pinned action SHAs with plain tags.
- Do not add broad permissions in GitHub workflows without necessity.
- Do not introduce destructive git operations (`reset --hard`, etc.) unless explicitly asked.

## If You Add New Tools
When adding another CLI to the image:
1. Add pinned version ARG in `Dockerfile` when applicable.
2. Install in `scripts/install-devops-tools.sh`.
3. Add integrity verification.
4. Add a sanity check command.
5. Extend `scripts/update-tool-versions.sh` if auto-refresh is desired.
6. Document it in `README.md`.

## Preferred Agent Output Style
- Be direct and technical.
- State what changed, why, and any residual risk.
- Include file paths for every modification.
- If validation was not run, say so explicitly.
