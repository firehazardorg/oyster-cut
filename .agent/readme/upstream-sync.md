# Upstream Sync & Private Fork (Oyster)

## Remotes

- `origin` → `https://github.com/logseq/logseq.git` (upstream, fetch only)
- `private` → `git@github.com:firehazardorg/oyster-cut.git` (our private fork, push here)

## Daily Workflow

```bash
# Pull latest from upstream logseq
git fetch origin

# Rebase our work on top of latest master
git rebase origin/master

# Push to private repo (use --force after rebase since lease will be stale)
git push private master --force
```

> **Note:** `--force-with-lease` will fail after a rebase because the local ref
> info is stale. Use `--force` instead — this is safe since oyster is our
> private fork and we only force-push our rebased commits.

## Branch Model

```
origin/master   ──A──B──C──D──E──  (upstream logseq)
                              \
our changes     ──────────────X──Y──Z  (our commits, rebased on top)
```

Use a feature branch to keep our commits separate from upstream:

```bash
git checkout -b my-features
# ... make changes ...
git rebase master my-features
git push private my-features --force-with-lease
```

## Known Conflict Points

Files we modify that upstream also changes — expect conflicts here during rebase:

| File | Our Change | Resolution |
|------|-----------|------------|
| `src/main/frontend/config.cljs` | Custom sync endpoints (workers.dev URLs) and `ENABLE-DB-SYNC-LOCALHOST` flag | Keep our URLs: `<SYNC_WORKER_DOMAIN>` (dev) and `logseq-sync-prod.logseq.workers.dev` (prod). Upstream uses `api.logseq.io`. |
| `resources/forge.config.js` | Signing identity for macOS builds | Keep our identity (env-driven via `APPLE_SIGN_IDENTITY`). Upstream uses `Logseq Inc. (K378MFWK59)`. |

## Minimizing Conflicts

- Prefer adding new files/namespaces over modifying upstream files
- Track modified upstream files: `git diff origin/master --name-only`
- Keep a note of what we've changed and why (reduces confusion during rebase conflicts)
- When conflicts arise, always keep **our** custom values (URLs, signing identities, bundle IDs)

## Licensing Note

Logseq is AGPL-3.0. Internal tooling (not distributed) is fine as a private fork.
Distributing the product requires making modifications public under AGPL.
