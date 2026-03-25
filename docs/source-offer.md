# Source Offer and Deployment Linkage

This document defines how Oyster satisfies AGPL source-availability
requirements for distributed binaries and network deployments.

## Requirements
1. Every public deployment must reference the exact source commit running in
   production.
2. Every published binary/release must link back to the exact source revision.
3. If modified versions are deployed publicly, the modified corresponding source
   must be available under AGPL-3.0 terms.

## Minimum Operational Policy
1. Tag each release with a git tag in this repository.
2. Record the release tag, commit SHA, and date in release notes.
3. Ensure the app/about page or deployment metadata includes a source link.
4. Keep `LICENSE.md`, `NOTICE`, and `ATTRIBUTION.md` in the repository root.

## Recommended Source Link Format
- Repository: `https://github.com/firehazardorg/oyster-cut`
- Commit: `https://github.com/firehazardorg/oyster-cut/commit/<sha>`
- Tag: `https://github.com/firehazardorg/oyster-cut/releases/tag/<tag>`

## Upstream Traceability
Track upstream remotes, mirror branches, and sync points in `UPSTREAMS.yaml`.
