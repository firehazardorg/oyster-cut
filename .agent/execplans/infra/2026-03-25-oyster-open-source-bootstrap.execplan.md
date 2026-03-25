# Execute Oyster Open-Source Bootstrap (Simplified)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

Bootstrap `oyster-cut` as a clean public repository that preserves Logseq upstream git history for AGPL traceability, replays sanitized Oyster commits on top, and includes compliance docs + a readiness scanner. Huncho integration and sync tooling are deferred until needed.

## Progress

- [x] (2026-03-25 05:13Z) Saved strategy plan to `.agent/plan/open-source-plan.md`.
- [x] (2026-03-25 05:13Z) Added compliance documents: `UPSTREAMS.yaml`, `NOTICE`, `ATTRIBUTION.md`, `docs/source-offer.md`.
- [x] (2026-03-25 05:13Z) Added `scripts/open-source/scan-readiness.sh`.
- [x] (2026-03-25 05:13Z) Replaced hardcoded sensitive values with placeholders in config files.
- [x] (2026-03-25 05:13Z) Created local branch topology: `main`, `integration/main`, `upstream/logseq`.
- [x] (2026-03-25 05:13Z) Added remote `public` → `git@github.com:firehazardorg/oyster-cut.git`.
- [x] (2026-03-25 05:13Z) Added `.env.open-source.example` template.
- [ ] Step 1: Set up oyster-cut repo at `/Users/shaunak/codebase/apps/oyster-cut` from upstream/logseq history.
- [ ] Step 2: Scrub all sensitive data in Oyster-specific files.
- [ ] Step 3: Commit scrubbed Oyster changes + compliance docs as clean commits on main.
- [ ] Step 4: Run readiness scan to validate zero sensitive patterns.
- [ ] Step 5: Push upstream/logseq, integration/main, main to public remote.

## Decision Log

- Decision: Defer Huncho subtree integration and sync-upstream.sh tooling until a real Huncho remote exists.
  Rationale: shipping unused scaffolding adds complexity without value; the architecture supports adding it later.
  Date/Author: 2026-03-25 / Claude

- Decision: Use flat file scrub + single Oyster commit instead of replaying 16 individual commits.
  Rationale: 16 commits is small; most are config/setup changes that make more sense as one coherent "configure Oyster fork" commit. Reduces risk of missing a secret in one of 16 cherry-picks.
  Date/Author: 2026-03-25 / Claude

- Decision: Keep `.agent/` directory in public repo with scrubbed placeholders.
  Rationale: user explicitly wants .agent/ kept; docs are useful for contributors when personal identifiers are replaced.
  Date/Author: 2026-03-25 / Claude

## Concrete Steps

Working directory: `/Users/shaunak/codebase/apps/oyster-cut`

### Step 1: Bootstrap from upstream Logseq history

```bash
rm -rf /Users/shaunak/codebase/apps/oyster-cut
git clone --no-checkout https://github.com/logseq/logseq.git /Users/shaunak/codebase/apps/oyster-cut
cd /Users/shaunak/codebase/apps/oyster-cut
git checkout -b upstream/logseq origin/master
git checkout -b integration/main
git checkout -b main
git remote remove origin
git remote add origin git@github.com:firehazardorg/oyster-cut.git
git remote add upstream-logseq https://github.com/logseq/logseq.git
```

This gives us full Logseq history for AGPL traceability with clean branch topology.

### Step 2: Copy Oyster-modified files from private repo

From the private repo (`/Users/shaunak/codebase/apps/logseq`), copy all files that differ from upstream. These are the files changed in the 16 Oyster commits. Then scrub any remaining sensitive values.

Files to copy (from `git diff --name-only upstream/logseq..master` in private repo):
- `.agent/` directory (entire, then scrub)
- `.github/workflows/clj-e2e.yml`
- `.gitignore`
- `bb.edn`
- `deps/db-sync/worker/wrangler.toml` (already scrubbed in working tree)
- `deps/publish/worker/wrangler.toml`
- `ios/` changes (fastlane, entitlements, pbxproj, Info.plist, gitignore)
- `resources/forge.config.js`
- `scripts/patch-xcode-project-oyster.sh`
- `shadow-cljs.edn`
- `src/main/frontend/config.cljs`
- `src/main/frontend/handler/user.cljs`
- Compliance docs: `UPSTREAMS.yaml`, `NOTICE`, `ATTRIBUTION.md`, `docs/source-offer.md`
- `.env.open-source.example`
- `scripts/open-source/scan-readiness.sh`

### Step 3: Scrub sensitive values

Replace in copied files:
- Personal email addresses → `<your-apple-id>`
- Apple Team ID → `<your-team-id>`
- ASC API Key ID → `<your-api-key-id>`
- ASC Issuer ID → `<your-issuer-id>`
- CLI API tokens → `<your-api-token>`
- Personal Cloudflare worker URLs → `<your-sync-worker>.workers.dev`
- Specific .p8 filenames → `*.p8` (generic gitignore pattern)
- D1 database IDs → `<your-d1-id>`
- Cognito pool/client IDs → placeholders
- Sentry DSN → `<your-sentry-dsn>`
- Personal names → `Oyster Contributors`
- Personal fastlane certs repo → `<your-fastlane-certs-repo>`

### Step 4: Commit and validate

```bash
git add -A
git commit -m "chore: configure Oyster fork with scrubbed credentials and AGPL compliance docs"
```

Run readiness scan against the commit to validate zero leaks.

### Step 5: Push to public remote

```bash
git push -u origin upstream/logseq integration/main main
```

## Validation and Acceptance

1. Readiness scan passes (zero pattern matches for known sensitive values)
2. `git log --oneline upstream/logseq | head` shows Logseq upstream history
3. `git log --oneline main` shows Logseq history + one clean Oyster commit
4. Fresh clone builds with `yarn install && yarn watch`
5. No personal emails, API keys, or account IDs in tracked files

## Artifacts

- Private repo: `/Users/shaunak/codebase/apps/logseq` (unchanged, continues as internal dev repo)
- Public repo: `/Users/shaunak/codebase/apps/oyster-cut` → `git@github.com:firehazardorg/oyster-cut.git`
- 16 Oyster commits in private repo map to 1 clean commit in public repo
