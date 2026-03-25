# Open-Sourcing Oyster with a Multi-Upstream Hybrid Split+Merge Model

## Summary
Adopt a **three-lane git model**: immutable upstream mirrors, an integration branch, and a product branch.  
This satisfies your constraints: continuous sync from Logseq and Huncho, no history rewrites, AGPL traceability, monorepo scalability, and a clean Oyster-facing structure.

Repository lanes:

```text
upstream/logseq  ----\
                      > integration/main ----> main (product)
upstream/huncho  ----/
```

Huncho is integrated as a first-class subsystem under `packages/huncho` with full history (non-squashed subtree), so product code stays clean while upstream lineage remains auditable.

## Important Public Interfaces, Contracts, and Types
1. **Git branch contract**: `upstream/logseq` and `upstream/huncho` are mirror-only and protected; `integration/main` accepts only merge commits from sync branches; `main` accepts merges from `integration/main` plus Oyster commits.
2. **Upstream metadata contract**: add `UPSTREAMS.yaml` with fields `name`, `remote_url`, `default_branch`, `mirror_branch`, `integration_method`, `subtree_prefix`, `last_synced_sha`, and `last_synced_at`.
3. **Sync operation interface**: add a single non-rewriting sync command surface (for example a Babashka task) that takes `--upstream logseq|huncho` and creates `sync/<upstream>/<date>` branches from `integration/main`.
4. **Compliance surface**: add `NOTICE`, `ATTRIBUTION.md`, and `docs/source-offer.md` as stable public compliance docs; all releases and hosted deployments must link to the exact source commit.
5. **No runtime API changes required in this phase**: this plan changes repository/process interfaces, not app public runtime APIs.

## Execution Plan
1. **Security and legal preflight in private workspace**. Freeze inbound feature merges temporarily, run full-tree and full-history secret scans, and build a credential rotation matrix. Revoke and rotate all exposed high-risk credentials before any public bootstrap. Treat the currently identified values as compromised and replaced, including Apple Connect key material references, CLI token references, and private infra credentials.
2. **Do not publish the existing private branch history directly**. Keep your private repo intact for internal continuity, but bootstrap `oyster-cut` from clean upstream histories plus sanitized Oyster commits. This avoids history rewrites while ensuring the public repo never contains leaked material.
3. **Bootstrap `oyster-cut` as a new git repository with upstream lineage preserved**. Initialize from Logseq upstream history first, set `origin` to `git@github.com:firehazardorg/oyster-cut.git`, create protected `upstream/logseq`, `integration/main`, and `main` branches, and push these as the public baseline.
4. **Add Huncho as a mirrored upstream and integrate with full history**. Add Huncho remote, mirror into `upstream/huncho`, then integrate into `integration/main` using non-squashed subtree at `packages/huncho`. This gives clean product layout and full commit ancestry for AGPL traceability.
5. **Replay Oyster customization as sanitized commit series**. Reconstruct your Oyster-specific work as new commits on `main` in chronological order, preserving intent but removing secrets and personal identifiers. Replace sensitive docs/config with templates (`*.example`) and environment-driven runtime config. Keep a `docs/history-map.md` that maps private commit IDs to new public commit IDs.
6. **Establish continuous multi-upstream sync flow**. For each upstream sync, create `sync/logseq/<date>` or `sync/huncho/<date>` from `integration/main`, merge upstream delta with merge commits only, resolve conflicts in that sync branch, then merge into `integration/main`, and finally merge integration into `main`. No rebase merges, no force pushes, no squash merges on upstream sync PRs.
7. **Apply repository governance and protections before broad collaboration**. Enable branch protection on all long-lived branches, disallow force-push, require PR reviews, require passing CI, and require signed commits if desired. Add `CODEOWNERS` for integration-critical paths and compliance files.
8. **Implement AGPL compliance artifacts and product-facing source traceability**. Keep AGPL license at repo root, add explicit attribution to Logseq and Huncho with URLs and tracked SHAs, and add a visible “Source Code” link in product surfaces that points to the exact running commit tag.
9. **Launch sequence**. Push initial clean history and branch topology, open a public “Open Source Readiness” issue with checklist, complete first dual-upstream sync rehearsal, tag `v0.1.0-open`, then announce contribution flow and sync cadence publicly.

## Test Cases and Scenarios
1. **Secret hygiene gate**: full-history and working-tree secret scans report zero high-confidence leaks on `main`, `integration/main`, and both `upstream/*` branches.
2. **Lineage verification**: `git merge-base` checks confirm `upstream/logseq` lineage is intact and `packages/huncho` commits trace back to `upstream/huncho`.
3. **No-rewrite policy validation**: branch protection blocks force-push attempts to `main`, `integration/main`, and `upstream/*`.
4. **Sync rehearsal from Logseq**: execute one real sync cycle and verify merge-only history and passing build/tests.
5. **Sync rehearsal from Huncho**: execute one real sync cycle and verify subtree path integrity plus passing build/tests.
6. **Compliance check**: verify `LICENSE.md`, `NOTICE`, `ATTRIBUTION.md`, and source-offer link are present and correct in release artifacts.
7. **Developer experience check**: fresh clone builds and tests with documented commands; no private credentials required for baseline development path.

## Assumptions and Defaults
1. Default branch model is exactly `upstream/logseq`, `upstream/huncho`, `integration/main`, and `main`.
2. Huncho integration default is non-squashed subtree under `packages/huncho` to preserve history and keep product structure clean.
3. `.agent/**`, `.claude/**`, and release/operator docs containing personal identifiers are removed from the public repo or replaced with redacted templates.
4. Existing private credentials and tokens referenced in prior exploration are treated as rotated before any public push.
5. No history rewrites will occur after `oyster-cut` is first pushed publicly; all updates happen through merge commits only.
