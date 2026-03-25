# Upstream Sync & Repository Management (Oyster)

## Repository

| | |
|---|---|
| Local Path | `/Users/shaunak/codebase/apps/oyster-cut` |
| GitHub | `firehazardorg/oyster-cut` |
| License | AGPL-3.0 (all modifications public) |

## Git Remotes

| Remote | URL | Purpose |
|--------|-----|---------|
| `origin` | `git@github.com:firehazardorg/oyster-cut.git` | Our public repo (push here) |
| `upstream-logseq` | `https://github.com/logseq/logseq.git` | Upstream Logseq (fetch only) |

## Branch Model (Three-Lane)

```
upstream/logseq      ──A──B──C──D──E──     (mirror of logseq/logseq master)
                                    \
integration/main     ────────────────M──   (merge upstream here first; test)
                                      \
main                 ──────────────────N── (stable; default branch)
```

- `upstream/logseq` — read-only mirror of `logseq/logseq:master`
- `integration/main` — upstream merges land here first; validate before promoting
- `main` — stable default branch; what users clone

---

## Scenario 1: Sync Upstream Logseq

### Option A: Using `sync-upstream.sh`

```bash
cd /Users/shaunak/codebase/apps/oyster-cut

scripts/open-source/sync-upstream.sh --upstream logseq
```

This will:
1. Fetch `upstream-logseq/master`
2. Fast-forward the `upstream/logseq` mirror branch
3. Create a `sync/logseq/YYYY-MM-DD` branch from `integration/main`
4. Merge the mirror branch into the sync branch

Then manually:
```bash
# Resolve conflicts if any, test the sync branch, then merge
git checkout integration/main
git merge sync/logseq/YYYY-MM-DD

# After validation, promote to main
git checkout main
git merge integration/main

# Push all branches
git push origin upstream/logseq integration/main main
```

### Option B: Manual sync

```bash
# Update the mirror branch
git fetch upstream-logseq master
git checkout upstream/logseq
git merge --ff-only upstream-logseq/master

# Merge into integration
git checkout integration/main
git merge --no-ff upstream/logseq -m "chore(sync): merge logseq upstream (YYYY-MM-DD)"

# Resolve conflicts, test, then promote to main
git checkout main
git merge integration/main

# Push
git push origin upstream/logseq integration/main main
```

---

## Scenario 2: New Feature Development

```bash
git checkout main
git checkout -b feature/my-feature

# ... make changes ...

# Push feature branch
git push origin feature/my-feature

# After review, merge into main
git checkout main
git merge feature/my-feature
git push origin main
```

---

## Scenario 3: Resolving Merge Conflicts During Upstream Sync

```bash
# After a merge conflict during sync:
git status  # see conflicted files

# Edit conflicted files — keep OUR values for known conflict points (see table below)
git add <resolved-file>
git commit  # complete the merge

# If things go wrong, abort
# git merge --abort
```

---

## Known Conflict Points

Files we modify that upstream also touches — always keep **our** values:

| File | Our Change | Keep Ours |
|------|-----------|-----------|
| `src/main/frontend/config.cljs` | Custom sync endpoints and `ENABLE-DB-SYNC-LOCALHOST` flag | Our worker URLs and the `ENABLE-DB-SYNC-LOCALHOST` goog-define block |
| `resources/forge.config.js` | macOS signing identity | Our env-driven identity (`process.env.APPLE_SIGN_IDENTITY`) |
| `src/main/frontend/handler/user.cljs` | `rtc-group?` returns `true` for all users | Keep `true` — upstream gates sync behind feature flags |
| `ios/App/App.xcodeproj/project.pbxproj` | Bundle IDs `com.firehazard.oyster.*` | Keep our bundle IDs |
| `ios/App/App/Info.plist` | Display name, URL scheme, iCloud container | Keep Oyster values |
| `.github/workflows/clj-e2e.yml` | `ENABLE-DB-SYNC-LOCAL true` closure define | Keep so E2E tests use our sync server |

### Minimizing Conflicts

- Prefer adding new files/namespaces over modifying upstream files
- Track what we've changed: `git diff upstream/logseq --name-only`
- When conflicts arise, always keep **our** custom values (URLs, signing identities, bundle IDs)

---

## Sensitive Values Reference

Values that must never appear in tracked files. The readiness scanner (`scripts/open-source/scan-readiness.sh`) checks for all of these.

| Value | Replace With |
|-------|-------------|
| Personal email addresses | `<your-apple-id>` |
| Apple Team ID | `<your-team-id>` |
| ASC API Key ID | `<your-api-key-id>` |
| ASC Issuer ID | `<your-issuer-id>` |
| Worker URLs (personal subdomains) | `<your-sync-worker>.workers.dev` |
| D1 database IDs | `<your-d1-id>` |
| Sentry DSN | `<your-sentry-dsn>` |
| Fastlane certs repo | `<your-fastlane-certs-repo>` |
| `.p8` key filenames | Generic `*.p8` pattern in `.gitignore` |
| Personal names | `Oyster Contributors` |

### Running the Readiness Scan

```bash
BASE_REF=upstream/logseq scripts/open-source/scan-readiness.sh
```

---

## Quick Reference

```bash
# Sync upstream (scripted)
scripts/open-source/sync-upstream.sh --upstream logseq

# See what we changed vs upstream
git diff upstream/logseq --name-only

# Run readiness scan
BASE_REF=upstream/logseq scripts/open-source/scan-readiness.sh

# Push all branches
git push origin upstream/logseq integration/main main
```
